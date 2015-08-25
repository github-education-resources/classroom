class AssignmentInvitationsController < InvitationsController
  skip_before_action :set_organization, :authorize_organization_access

  def accept_invitation
    if (full_repo_name = @invitation.redeem_for(current_user))
      render partial: 'invitations/success',
             locals: { repo_url: "https://github.com/#{full_repo_name}" },
             layout: 'invitations'
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  private

  def set_invitation
    @invitation = AssignmentInvitation.find_by_key!(params[:id])
  end
end
