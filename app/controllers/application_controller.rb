# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Errors
  include FeatureFlags

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  helper_method :current_user, :logged_in?, :true_user
  helper_method :student_identifier_enabled?, :team_management_enabled?

  # errors_dependency
  rescue_from GitHub::Error,
              GitHub::Forbidden,
              GitHub::NotFound,
              NotAuthorized, with: :flash_and_redirect_back_with_message

  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, with: :render_404

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
