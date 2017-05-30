# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  require 'application_controller/authentication_dependency'
  require 'application_controller/errors_dependency'
  require 'application_controller/feature_flags_dependency'

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
