class AssignmentInvitationsController < InvitationsController
  before_action :set_assignment, :set_organization
  before_action :verify_not_already_accepted_invitation, only: [:show]
  before_action :set_assignment_repo, only: [:successful_invitation]

  decorates_assigned :organization

  def accept_invitation
    if (assignment_repo = @invitation.redeem_for(current_user))
      redirect_to successful_invitation_assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def successful_invitation
    not_found unless @assignment_repo
    @decorated_assignment_repo = @assignment_repo.decorate
  end

  private

  def set_assignment
    @assignment = @invitation.assignment
  end

  def set_assignment_repo
    repo_access      = current_user.repo_accesses.find_by(organization: @assignment.organization)
    @assignment_repo = AssignmentRepo.find_by(assignment: @assignment, repo_access: repo_access)
  end

  def set_invitation
    @invitation = AssignmentInvitation.find_by_key!(params[:id])
  end

  def set_organization
    @organization = @assignment.organization
  end

  def verify_not_already_accepted_invitation
    return if !@assignment.users.include?(current_user)
    redirect_to successful_invitation_assignment_invitation_path
  end
end
