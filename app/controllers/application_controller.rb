# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  class NotAuthorized < StandardError
  end

  helper_method :current_user, :logged_in?, :staff?, :true_user

  before_action :authenticate_user!

  rescue_from GitHub::Error,     with: :flash_and_redirect_back_with_message
  rescue_from GitHub::Forbidden, with: :flash_and_redirect_back_with_message
  rescue_from GitHub::NotFound,  with: :flash_and_redirect_back_with_message
  rescue_from NotAuthorized,     with: :flash_and_redirect_back_with_message

  def peek_enabled?
    staff?
  end

  private

  def current_scopes
    return [] unless logged_in?
    session[:current_scopes] ||= current_user.github_client_scopes
  end

  def required_scopes
    if Classroom.flipper[:explicit_assignment_submission].enabled? current_user
      Classroom::Scopes::ExplicitSubmission::TEACHER
    else
      Classroom::Scopes::TEACHER
    end
  end

  def adequate_scopes?
    required_scopes.all? { |scope| current_scopes.include?(scope) }
  end

  def authenticate_user!
    return become_active if logged_in? && adequate_scopes?
    auth_redirect
  end

  def auth_redirect
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    session[:required_scopes] = required_scopes.join(',')
    redirect_to login_path
  end

  def become_active
    current_user.become_active
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = if true_user.try(:staff?) && session[:impersonated_user_id]
                      User.find session[:impersonated_user_id]
                    else
                      true_user
                    end
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
    raise ActionController::RoutingError, 'Not Found'
  end

  def redirect_to_root
    redirect_to root_path
  end

  def staff?
    logged_in? && current_user.staff?
  end

  def true_user
    @true_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
