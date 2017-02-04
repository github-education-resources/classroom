# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  class NotAuthorized < StandardError
  end

  helper_method :current_user, :logged_in?, :staff?, :true_user, :student_identifier_enabled?, :team_management_enabled?

  before_action :authenticate_user!

  rescue_from GitHub::Error,     with: :flash_and_redirect_back_with_message
  rescue_from GitHub::Forbidden, with: :flash_and_redirect_back_with_message
  rescue_from GitHub::NotFound,  with: :flash_and_redirect_back_with_message
  rescue_from NotAuthorized,     with: :flash_and_redirect_back_with_message

  def peek_enabled?
    staff?
  end

  private

  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def ensure_student_identifier_flipper_is_enabled
    not_found unless student_identifier_enabled?
  end

  def current_scopes
    return [] unless logged_in?
    session[:current_scopes] ||= current_user.github_client_scopes
  end

  def required_scopes
    GitHubClassroom::Scopes::TEACHER
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
    LastActiveJob.perform_later(current_user.id, Time.zone.now.to_i)
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = if true_user.try(:staff?) && session[:impersonated_user_id]
                      User.find_by(id: session[:impersonated_user_id])
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
        flash[:error] = 'Uh oh, an error has occurred.'
      end
    end

    redirect_back(fallback_location: root_path)
  end

  def logged_in?
    !current_user.nil?
  end

  def student_identifier_enabled?
    GitHubClassroom.flipper[:student_identifier].enabled?(current_user)
  end

  def team_management_enabled?
    GitHubClassroom.flipper[:team_management].enabled?(current_user)
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
    @true_user ||= User.find_by(id: session[:user_id])
  end
end
