# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class GroupAssignmentInvitationsController < ApplicationController
  class InvalidStatusForRouteError < StandardError; end

  include InvitationsControllerMethods

  layout "layouts/invitations"

  before_action :route_based_on_status,                  only: %i[setup successful_invitation]
  before_action :check_group_not_previous_acceptee,      only: :show
  before_action :check_user_not_group_member,            only: :show
  before_action :check_should_redirect_to_roster_page,   only: :show
  before_action :authorize_group_access,                 only: :accept_invitation
  before_action :ensure_github_repo_exists,              only: :successful_invitation
  before_action :ensure_group_import_resiliency_enabled, only: %i[create_repo progress]

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

    create_group_assignment_repo(selected_group: selected_group, new_group_title: selected_group_title) do
      redirect_to successful_invitation_group_assignment_invitation_path
    end
  end

  def setup
    not_found unless organization.feature_enabled?(:group_import_resiliency)
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def create_repo
    job_started =
      if group_invite_status.accepted? || group_invite_status.errored?
        if group_assignment_repo&.github_repository&.empty?
          group_assignment_repo&.destroy
          @group_assignment_repo = nil
        end
        report_retry
        group_invite_status.waiting!
        GroupAssignmentRepo::CreateGitHubRepositoryJob.perform_later(group_assignment, group, retries: 3)
        true
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

  def ensure_group_import_resiliency_enabled
    not_found unless organization.feature_enabled?(:group_import_resiliency)
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def route_based_on_status
    return unless organization.feature_enabled?(:group_import_resiliency)
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

  def check_group_not_previous_acceptee
    return unless group.present? && group_assignment_repo.present?

    redirect_to successful_invitation_group_assignment_invitation_path
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
      if organization.feature_enabled?(:group_import_resiliency)
        GitHubClassroom.statsd.increment("v2_group_exercise_invitation.accept")
        route_based_on_status
      else
        GitHubClassroom.statsd.increment("group_exercise_invitation.accept")
        yield if block_given?
      end
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
    if organization.feature_enabled?(:group_import_resiliency)
      GitHubClassroom.statsd.increment("v2_group_exercise_invitation.fail")
    else
      GitHubClassroom.statsd.increment("group_exercise_invitation.fail")
    end
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
end
# rubocop:enable Metrics/ClassLength
