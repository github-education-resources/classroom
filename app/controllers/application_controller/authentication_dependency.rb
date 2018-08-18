# frozen_string_literal: true

class ApplicationController
  private

  def current_scopes
    return [] unless logged_in?
    session[:current_scopes] = current_user.github_client_scopes
  end

  def required_scopes
    GitHubClassroom::Scopes::TEACHER
  end

  def adequate_scopes?
    current_expanded_scopes = GitHub::Token.expand_scopes(current_scopes)
    GitHub::Token.expand_scopes(required_scopes).all? do |scope|
      current_expanded_scopes.include?(scope)
    end
  end

  def authenticate_user!
    if logged_in?
      return log_out_and_flash unless current_user.authorized_access_token?
      return become_active if adequate_scopes?
    end
    auth_redirect
  end

  def auth_redirect
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    session[:required_scopes] = required_scopes.join(",")
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

  def log_out_and_flash
    log_out
    flash[:error] = "Access Token is invalid. Please login again."
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    reset_session
    redirect_to root_path
  end

  def true_user
    @true_user ||= User.find_by(id: session[:user_id])
  end
end
