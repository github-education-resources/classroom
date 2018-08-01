# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
class API::ApplicationController < ApplicationController
  include Rails::Pagination

  prepend_before_action :ensure_download_repositories_flipper_is_enabled
  prepend_before_action :verify_jwt_token

  # Skip CSRF checks for API since it's token based
  skip_before_action :verify_authenticity_token

  def authenticate_user!
    return become_active if logged_in? && adequate_scopes? && current_user.authorized_access_token?
    render_forbidden
  end

  def verify_jwt_token
    if params[:access_token].present?
      data = JsonWebToken.decode(params[:access_token])
      unless data.nil? || data[:user_id].nil?
        return session[:user_id] = data[:user_id]
      end
    end
    render_forbidden
  end

  private

  def render_forbidden
    render json: {
      message: "Unauthorized"
    }, status: :forbidden
  end
end
# rubocop:enable ClassAndModuleChildren
