# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class GroupAssignmentInvitationsController < ApplicationController
  class InvalidStatusForRouteError < StandardError; end

  include InvitationsControllerMethods

  layout "layouts/invitations"

  before_action :route_based_on_status,                  only: %i[setupv2 successful_invitation]
  before_action :check_group_not_previous_acceptee,      only: :show
  before_action :check_user_not_group_member,            only: :show
  before_action :check_should_redirect_to_roster_page,   only: :show
  before_action :authorize_group_access,                 only: :accept_invitation
  before_action :ensure_github_repo_exists,              only: :successful_invitation
  before_action :ensure_group_import_resiliency_enabled, only: %i[create_repo progress]

  def show
    @groups = invitation.groups.map { |group| [group.title, group.id] }
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

  def setupv2
    not_found unless group_import_resiliency_enabled?
  end

  def create_repo
    raise NotImplementedError
  end

  def progress
    render json: { status: group_invite_status&.status }
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
    return unless group_import_resiliency_enabled?
    status = group_invite_status&.status
    return if status.blank?
    case status
    when "unaccepted"
      redirect_to accept_group_assignment_invitation_path(invitation) if action_name != "accept"
    when "completed"
      redirect_to successful_invitation_group_assignment_invitation_path if action_name != "successful_invitation"
    when *(GroupInviteStatus::ERRORED_STATUSES + GroupInviteStatus::SETUP_STATUSES)
      redirect_to setupv2_group_assignment_invitation_path if action_name != "setupv2"
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

    GitHubClassroom.statsd.increment("group_exercise_invitation.fail")
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

  def ensure_group_import_resiliency_enabled
    render status: 404, json: { error: "Not found" } unless group_import_resiliency_enabled?
  end

  ## Controller Method Helpers

  # rubocop:disable Metrics/AbcSize
  def validate_max_members_not_exceeded!(group)
    return unless group.present? && group_assignment.present? && group_assignment.max_members.present?
    return unless group.repo_accesses.count >= group_assignment.max_members

    GitHubClassroom.statsd.increment("group_exercise_invitation.fail")
    raise NotAuthorized, "This team has reached its maximum member limit of #{group_assignment.max_members}."
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def create_group_assignment_repo(selected_group: group, new_group_title: nil)
    if !invitation.enabled?
      flash[:error] = "Invitations for this assignment have been disabled."
      redirect_to group_assignment_invitation_path
    else
      users_group_assignment_repo = invitation.redeem_for(current_user, selected_group, new_group_title)

      if users_group_assignment_repo.present?
        GitHubClassroom.statsd.increment("group_exercise_invitation.accept")
        yield if block_given?
      else
        GitHubClassroom.statsd.increment("group_exercise_invitation.fail")

        flash[:error] = "An error has occurred, please refresh the page and try again."
        redirect_to group_assignment_invitation_path
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength

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
