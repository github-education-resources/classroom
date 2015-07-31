class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :staff?

  def peek_enabled?
    return unless current_user
    current_user.staff?
  end

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def ensure_logged_in
    return if logged_in?
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path, notice: 'You must be logged in to view this content.'
  end

  def logged_in?
    !current_user.nil?
  end

  def redirect_to_root
    redirect_to root_path
  end
end
