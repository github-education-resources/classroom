class GroupAssignmentInvitationsController < ApplicationController
  layout 'layouts/invitations'

  before_action :check_group_not_previous_acceptee, only: [:show]
  before_action :check_user_not_group_member,       only: [:show]

  before_action :authorize_group_access, only: [:accept_invitation]

  def show
    @groups = invitation.groups.map { |group| [group.title, group.id] }
  end

  def accept
  end

  def accept_assignment
    users_group_assignment_repo = invitation.redeem_for(current_user, group)

    if users_group_assignment_repo.present?
      redirect_to successful_invitation_group_assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def accept_invitation
    selected_group       = Group.find_by(id: group_params[:id])
    selected_group_title = group_params[:title]

    users_group_assignment_repo = invitation.redeem_for(current_user, selected_group, selected_group_title)

    if users_group_assignment_repo.present?
      redirect_to successful_invitation_group_assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def successful_invitation
    not_found unless group_assignment_repo
  end

  private

  def required_scopes
    %w(admin:org user:email)
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

  def decorated_group_assignment_repo
    @decorated_group_assignment_repo ||= group_assignment_repo.decorate
  end
  helper_method :decorated_group_assignment_repo

  def decorated_organization
    @decorated_organization ||= organization.decorate
  end
  helper_method :decorated_organization

  def decorated_group
    @decorated_group ||= group.decorate
  end
  helper_method :decorated_group

  def group
    repo_access = current_user.repo_accesses.find_by(organization: organization)
    return unless repo_access.present? && repo_access.groups.present?

    @group ||= repo_access.groups.find_by(grouping: group_assignment.grouping)
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

  def invitation
    @invitation ||= GroupAssignmentInvitation.find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= group_assignment.organization
  end
  helper_method :organization

  def check_group_not_previous_acceptee
    return unless group.present? && group_assignment_repo.present?
    redirect_to successful_invitation_group_assignment_invitation_path
  end

  def check_user_not_group_member
    return unless group.present?
    redirect_to accept_group_assignment_invitation_path
  end
end
