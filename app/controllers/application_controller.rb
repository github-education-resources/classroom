class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  class NotAuthorized < StandardError
  end

  helper_method :current_user, :decorated_current_user, :logged_in?, :staff?

  before_action :authenticate_user!

  rescue_from GitHub::Error,     with: :flash_and_redirect_back_with_message
  rescue_from GitHub::Forbidden, with: :flash_and_redirect_back_with_message
  rescue_from GitHub::NotFound,  with: :flash_and_redirect_back_with_message
  rescue_from NotAuthorized,     with: :flash_and_redirect_back_with_message

  def peek_enabled?
    staff?
  end

  private

  def authenticate_user!
    auth_redirect unless logged_in? && current_user.valid_auth_token?
  end

  def auth_redirect
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path
  end

  def decorated_current_user
    @decorated_current_user ||= current_user.decorate
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def flash_and_redirect_back_with_message(exception)
    flash[:error] = exception.message

    unless flash[:error].present?
      case exception
      when NotAuthorized
        flash[:error] = 'You are not authorized to perform this action'
      when GitHub::Error, GitHub::Forbidden, GitHub::NotFound
        flash[:error] = 'Uh oh, an error has occured.'
      end
    end

    redirect_to :back
  end

  def logged_in?
    !current_user.nil?
  end

  def not_found
    fail ActionController::RoutingError, 'Not Found'
  end

  def redirect_to_root
    redirect_to root_path
  end

  def staff?
    logged_in? && current_user.staff?
  end
end
