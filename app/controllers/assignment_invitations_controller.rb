class AssignmentInvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_invitation

  rescue_from GitHub::Forbidden,               with: :deny_access
  rescue_from GitHub::Error, GitHub::NotFound, with: :error

  def show
  end

  def accept_invitation
    if (full_repo_name = @invitation.redeem(current_user))
      @repo_url = "https://github.com/#{full_repo_name}"
    else
      render json: { message: 'An error has occured, please refresh the page and try again.',
                     status: :internal_server_error }
    end
  end

  private

  def authenticate_with_pre_login_destination
    return if logged_in?
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path
  end

  def deny_access
    message = 'You are currently not authorized to join this organization, please see an administrator for assistance'
    render json: { message: message }
  end

  def error(exception)
    default_message = 'Uh oh, an error has occured. Please refresh the page and try again'
    error_message   = exception.message.present? ? exception.message : default_message

    render json: { message: error_message }
  end

  def set_invitation
    @invitation = AssignmentInvitation.find_by_key!(params[:id])
  end
end
