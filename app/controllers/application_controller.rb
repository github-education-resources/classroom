# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  depends_on :authentication, :errors, :feature_flags

  before_action :authenticate_user! # authentication_dependency

  helper_method :current_user, :logged_in?, :true_user                  # authentication_dependency
  helper_method :student_identifier_enabled?, :team_management_enabled? # feature_flags_dependency

  # errors_dependency
  rescue_from StandardError, with: :send_to_statsd_and_reraise
  rescue_from GitHub::Error,
              GitHub::Forbidden,
              GitHub::NotFound,
              NotAuthorized, with: :flash_and_redirect_back_with_message
  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, with: :render_404

  rescue_from ActionController::InvalidAuthenticityToken do
    pre_login_destination = session[:pre_login_destination]
    reset_session

    session[:pre_login_destination] = pre_login_destination if pre_login_destination.present?
    url = session[:pre_login_destination] || root_path

    flash[:alert] = "Cannot verify CSRF Token Authenticity"
    redirect_to url
  end

  def peek_enabled?
    logged_in? && current_user.staff?
  end

  def failbot_context
    {
      current_scopes:  session[:current_scopes],
      impersonator:    session[:impersonated_user_id],
      required_scopes: session[:required_scopes],
      user:            session[:user_id],
      zone:            Time.zone.now
    }
  end

  private

  def not_found
    raise ActionController::RoutingError, "Not Found"
  end

  def redirect_to_root
    redirect_to root_path
  end

  def render_404(exception)
    GitHubClassroom.statsd.increment("exception.not_found", tags: [exception.class.to_s])

    case exception
    when ActionController::RoutingError
      render file: Rails.root.join("public", "404.html"), layout: false, status: :not_found
    when ActiveRecord::RecordNotFound
      render file: Rails.root.join("public", "invalid_link_error.html"), layout: false, status: :not_found
    end
  end
end
