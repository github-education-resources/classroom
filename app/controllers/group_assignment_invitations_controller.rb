# frozen_string_literal: true

class GroupAssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods

  before_action :check_group_not_previous_acceptee, only: [:show]
  before_action :check_user_not_group_member,       only: [:show]

  before_action :authorize_group_access, only: [:accept_invitation]

  before_action :ensure_github_repo_exists, only: [:successful_invitation]

  def show
    @groups = invitation.groups.map { |group| [group.title, group.id] }
  end

  def accept; end

  def accept_assignment
    create_submission do
      redirect_to success_group_assignment_invitation_path
    end
  end

  def accept_invitation
    selected_group       = Group.find_by(id: group_params[:id])
    selected_group_title = group_params[:title]

    options = {
      selected_group: selected_group,
      new_group_title: selected_group_title
    }

    create_submission(options) do
      redirect_to success_group_assignment_invitation_path
    end
  end

  private

  def authorize_group_access
    group_id = group_params[:id]

    return if group_id.blank?
    group = Group.find(group_id)
    validate_max_members_not_exceeded!(group)
    return if current_assignment.grouping.groups.find_by(id: group_id)

    raise NotAuthorized, 'You are not permitted to select this team'
  end

  def check_group_not_previous_acceptee
    return unless group.present? && group_assignment_repo.present?
    redirect_to success_group_assignment_invitation_path
  end

  def check_user_not_group_member
    return if group.blank?
    redirect_to accept_group_assignment_invitation_path
  end

  def create_submission(selected_group: group, new_group_title: nil)
    users_group_assignment_repo = current_invitation.redeem_for(current_user, selected_group, new_group_title)

    if users_group_assignment_repo.present?
      yield if block_given?
    else
      flash[:error] = 'An error has occurred, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def current_invitation
    @invitation ||= GroupAssignmentInvitation
                    .includes(group_assignment: :group_assignment_repos)
                    .find_by!(key: params[:id])
  end

  def current_submission
    @current_submission ||= GroupAssignmentRepo.find_by(group_assignment: current_assignment, group: group)
  end

  def ensure_submission_repository_exists
    return not_found unless current_submission
    return if current_submission
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    group = current_submission.group

    current_submission.destroy
    remove_instance_variable(:@current_submission)
    create_submission(selected_group: group)
  end

  def group
    repo_access = current_user.repo_accesses.find_by(organization: organization)
    return unless repo_access.present? && repo_access.groups.present?

    @group ||= repo_access.groups.find_by(grouping: current_assignment.grouping)
  end
  helper_method :group

  def group_params
    params.require(:group).permit(:id, :title)
  end

  def required_scopes
    GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT
  end

  # TODO: This should be a model validation not at the
  # controller level.
  def validate_max_members_not_exceeded!(group)
    return unless group.present? && current_assignment.present? && current_assignment.max_members.present?
    return unless group.repo_accesses.count >= current_assignment.max_members
    raise NotAuthorized, "This team has reached its maximum member limit of #{current_assignment.max_members}."
  end
end
