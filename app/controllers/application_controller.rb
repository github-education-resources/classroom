# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  require 'application_controller/authentication_dependency'
  require 'application_controller/errors_dependency'
  require 'application_controller/feature_flags_dependency'

  before_action :authenticate_user! # authentication_dependency

  helper_method :current_user, :logged_in?, :true_user                  # authentication_dependency
  helper_method :student_identifier_enabled?, :team_management_enabled? # feature_flags_dependency

  # errors_dependency
  rescue_from GitHub::Error,
              GitHub::Forbidden,
              GitHub::NotFound,
              NotAuthorized, with: :flash_and_redirect_back_with_message

  def peek_enabled?
    logged_in? && current_user.staff?
  end

  private

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def redirect_to_root
    redirect_to root_path
  end
end
