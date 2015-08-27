class AssignmentInvitationsController < InvitationsController
  before_action :set_assignment
  before_action :verify_not_already_accepted_invitation, only: [:show]

  def accept_invitation
    if (assignment_repo = @invitation.redeem_for(current_user))
      render_successful_invitation(assignment_repo)
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  private

  def set_assignment
    @assignment = @invitation.assignment
  end

  def set_invitation
    @invitation = AssignmentInvitation.find_by_key!(params[:id])
  end

  def verify_not_already_accepted_invitation
    return if !@assignment.users.include?(current_user)

    assignment_repo = current_user.assignment_repos.find_by(assignment: @assignment)
    render_successful_invitation(assignment_repo)
  end

  def render_successful_invitation(assignment_repo)
    decorated_assignment_repo = assignment_repo.decorate
    github_repo_url           = decorated_assignment_repo.github_url

    render partial: 'invitations/success',
           locals: { assignment: @assignment, github_repo_url: github_repo_url },
           layout: 'invitations'
  end
end
