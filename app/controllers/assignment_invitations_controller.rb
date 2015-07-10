class AssignmentInvitationsController < InvitationsController
  def accept_invitation
    if (full_repo_name = @invitation.redeem_for(current_user))
      @repo_url = "https://github.com/#{full_repo_name}"
    else
      render json: { message: 'An error has occured, please refresh the page and try again.',
                     status: :internal_server_error }
    end
  end

  private

  def error(exception)
    render json: { message: super }
  end

  def set_invitation
    @invitation = AssignmentInvitation.find_by_key!(params[:id])
  end
end
