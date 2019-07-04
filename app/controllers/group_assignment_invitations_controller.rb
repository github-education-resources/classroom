# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class GroupAssignmentInvitationsController < ApplicationController
  class InvalidStatusForRouteError < StandardError; end

  include InvitationsControllerMethods

  layout "layouts/invitations"

  before_action :route_based_on_status,                  only: %i[setup successful_invitation]
  before_action :check_user_not_group_member,            only: :show
  before_action :check_should_redirect_to_roster_page,   only: :show
  before_action :authorize_group_access,                 only: :accept_invitation
  before_action :ensure_github_repo_exists,              only: :successful_invitation

  def show
    @groups = invitation.groups.order(:title).page(params[:page])
  end

  def accept; end

  def accept_assignment
    create_group_assignment_repo do
      redirect_to successful_invitation_group_assignment_invitation_path
    end
  end

  def accept_invitation
    selected_group       = Group.find_by(id: group_params[:id])
    selected_group_title = group_params[:title]
    validate_max_teams_not_exceeded! unless selected_group

    create_group_assignment_repo(selected_group: selected_group, new_group_title: selected_group_title) do
      redirect_to successful_invitation_group_assignment_invitation_path
    end
  end

  def setup
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def create_repo
    job_started =
      if group_invite_status.accepted? || group_invite_status.errored?
        if repo_ready?
          group_invite_status.completed!
          false
        else
          group_assignment_repo&.destroy
          @group_assignment_repo = nil
          report_retry
          group_invite_status.waiting!
          GroupAssignmentRepo::CreateGitHubRepositoryJob.perform_later(group_assignment, group, retries: 3)
          true
        end
      else
        false
      end
    render json: {
      job_started: job_started,
      status: group_invite_status.status,
      repo_url: group_assignment_repo&.github_repository&.html_url
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength

  def progress
    render json: {
      status: group_invite_status&.status,
      repo_url: group_assignment_repo&.github_repository&.html_url
    }
  end

  def successful_invitation; end

  def join_roster
    super

    redirect_to group_assignment_invitation_url(invitation)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error occured, please try again!"
  end

  private

  def required_scopes
    GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT
  end

  def group_params
    params
      .require(:group)
      .permit(:id, :title)
  end

  ## Before Actions

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def route_based_on_status
    status = group_invite_status&.status
    case status
    when "unaccepted", nil
      redirect_to group_assignment_invitation_path(invitation)
    when "completed"
      redirect_to successful_invitation_group_assignment_invitation_path if action_name != "successful_invitation"
    when *(GroupInviteStatus::ERRORED_STATUSES + GroupInviteStatus::SETUP_STATUSES)
      redirect_to setup_group_assignment_invitation_path if action_name != "setup"
    else
      raise InvalidStatusForRouteError, "No route registered for status: #{status}"
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  def authorize_group_access
    group_id = group_params[:id]

    return if group_id.blank?
    group = Group.find(group_id)
    validate_max_members_not_exceeded!(group)
    return if group_assignment.grouping.groups.find_by(id: group_id)

    report_invitation_failure
    raise NotAuthorized, "You are not permitted to select this team"
  end

  def check_user_not_group_member
    return if group.blank?
    redirect_to accept_group_assignment_invitation_path
  end

  def ensure_github_repo_exists
    return not_found unless group_assignment_repo
    return if group_assignment_repo
        .github_repository
        .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    group = group_assignment_repo.group

    group_assignment_repo.destroy
    @group_assignment_repo = nil
    create_group_assignment_repo(selected_group: group)
  end

  ## Controller Method Helpers

  # rubocop:disable Metrics/AbcSize
  def validate_max_members_not_exceeded!(group)
    return unless group.present? && group_assignment.present? && group_assignment.max_members.present?
    return unless group.repo_accesses.count >= group_assignment.max_members

    report_invitation_failure
    raise NotAuthorized, "This team has reached its maximum member limit of #{group_assignment.max_members}."
  end

  def validate_max_teams_not_exceeded!
    return unless group_assignment.present? && group_assignment.max_teams.present?
    return unless group_assignment.grouping.groups.count >= group_assignment.max_teams

    report_invitation_failure
    raise NotAuthorized, "This assignment has reached its team limit of #{group_assignment.max_teams}."\
      " Please join an existing team."
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def create_group_assignment_repo(selected_group: group, new_group_title: nil)
    result = invitation.redeem_for(
      current_user,
      selected_group,
      new_group_title
    )

    case result.status
    when :failed
      report_invitation_failure if invitation.enabled?
      flash[:error] = result.error
      redirect_to group_assignment_invitation_path
    when :success, :pending
      GitHubClassroom.statsd.increment("v2_group_exercise_invitation.accept")
      route_based_on_status
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength

  ## Datadog reporting convenience methods

  def report_retry
    if group_invite_status.errored_creating_repo?
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.retry")
    elsif group_invite_status.errored_importing_starter_code?
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.import.retry")
    end
  end

  def report_invitation_failure
    GitHubClassroom.statsd.increment("v2_group_exercise_invitation.fail")
  end

  ## Resource Helpers

  def group
    repo_access = current_user.repo_accesses.find_by(organization: organization)
    return unless repo_access.present? && repo_access.groups.present?

    @group ||= repo_access.groups.find_by(grouping: group_assignment.grouping)
  end
  helper_method :group

  def group_invite_status
    return if group.blank?
    @group_invite_status ||= invitation.status(group)
  end

  def group_assignment
    @group_assignment ||= invitation.group_assignment
  end
  helper_method :group_assignment

  def group_assignment_repo
    @group_assignment_repo ||= GroupAssignmentRepo.find_by(group_assignment: group_assignment, group: group)
  end
  helper_method :group_assignment_repo

  def invitation
    @invitation ||= GroupAssignmentInvitation
      .includes(group_assignment: :group_assignment_repos)
      .find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= group_assignment.organization
  end
  helper_method :organization

  def repo_ready?
    return false if group_assignment_repo.blank?
    return false if group_assignment.starter_code? && !group_assignment_repo.github_repository.imported?
    true
  end
end
# rubocop:enable Metrics/ClassLength
