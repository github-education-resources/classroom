class InvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_invitation

  layout 'layouts/invitations'

  rescue_from GitHub::Forbidden, GitHub::Error, GitHub::NotFound, with: :error

  def show; end

  private

  def authenticate_with_pre_login_destination
    return if logged_in?
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path
  end

  def error(exception)
    exception.message.present? ? exception.message : 'Uh oh, an error has occured.'
  end
end
