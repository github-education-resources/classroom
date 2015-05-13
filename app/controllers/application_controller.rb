class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def ensure_logged_in
    unless logged_in?
      redirect_to root_path, notice: 'You must be logged in to view this content.'
    end
  end

  def logged_in?
    !!current_user
  end
end
