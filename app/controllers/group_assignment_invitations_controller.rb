# frozen_string_literal: true
# rubocop:disable ClassLength
class GroupAssignmentInvitationsController < ApplicationController
  layout 'layouts/invitations'

  before_action :check_user_identified, only: [:show]
  before_action :check_group_not_previous_acceptee, only: [:show]
  before_action :check_user_not_group_member,       only: [:show]

  before_action :authorize_group_access, only: [:accept_invitation]

  before_action :ensure_github_repo_exists, only: [:successful_invitation]

  def show
    @groups = invitation.groups.map { |group| [group.title, group.id] }
  end

  def identifier
    not_found if student_identifier || group_assignment.student_identifier_type.nil?
    @student_identifier = StudentIdentifier.new
  end

  def submit_identifier
    @student_identifier = StudentIdentifier.new(new_student_identifier_params)
    if @student_identifier.save
      redirect_to group_assignment_invitation_path
    else
      render :identifier
    end
  end

  def accept
  end

  def accept_assignment
    create_group_assignment_repo { redirect_to successful_invitation_group_assignment_invitation_path }
  end

  def accept_invitation
    selected_group       = Group.find_by(id: group_params[:id])
    selected_group_title = group_params[:title]

    create_group_assignment_repo(selected_group: selected_group,
                                 new_group_title: selected_group_title) do
      redirect_to successful_invitation_group_assignment_invitation_path
    end
  end

  def successful_invitation
  end

  private

  def required_scopes
    GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT
  end

  def authorize_group_access
    group_id = group_params[:id]

    return unless group_id.present?
    group = Group.find(group_id)
    validate_max_members_not_exceeded!(group)
    return if group_assignment.grouping.groups.find_by(id: group_id)

    raise NotAuthorized, 'You are not permitted to select this team'
  end

  def validate_max_members_not_exceeded!(group)
    return unless group.present? && group_assignment.present? && group_assignment.max_members.present?
    return unless group.repo_accesses.count >= group_assignment.max_members
    raise NotAuthorized, "This team has reached its maximum member limit of #{group_assignment.max_members}."
  end

  def group
    repo_access = current_user.repo_accesses.find_by(organization: organization)
    return unless repo_access.present? && repo_access.groups.present?

    @group ||= repo_access.groups.find_by(grouping: group_assignment.grouping)
  end
  helper_method :group

  def create_group_assignment_repo(selected_group: group, new_group_title: nil)
    users_group_assignment_repo = invitation.redeem_for(current_user, selected_group, new_group_title)

    if users_group_assignment_repo.present?
      yield if block_given?
    else
      flash[:error] = 'An error has occurred, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def group_assignment
    @group_assignment ||= invitation.group_assignment
  end
  helper_method :group_assignment

  def group_assignment_repo
    @group_assignment_repo ||= GroupAssignmentRepo.find_by(group_assignment: group_assignment, group: group)
  end
  helper_method :group_assignment_repo

  def group_params
    params
      .require(:group)
      .permit(:id, :title)
  end

  def new_student_identifier_params
    params
      .require(:student_identifier)
      .permit(:value)
      .merge(user: current_user,
             organization: organization,
             student_identifier_type: group_assignment.student_identifier_type)
  end

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

  def student_identifier
    @student_identifier ||= StudentIdentifier.find_by(user: current_user,
                                                      student_identifier_type: group_assignment.student_identifier_type)
  end
  helper_method :student_identifier

  def check_user_identified
    return unless group_assignment.student_identifier_type.present?
    return if student_identifier.present?
    redirect_to identifier_group_assignment_invitation_path
  end

  def check_group_not_previous_acceptee
    return unless group.present? && group_assignment_repo.present?
    redirect_to successful_invitation_group_assignment_invitation_path
  end

  def check_user_not_group_member
    return unless group.present?
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
end
