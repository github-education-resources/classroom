# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
class API::ApplicationController < ApplicationController
  include Rails::Pagination

  before_action :ensure_download_repositories_flipper_is_enabled
  before_action :add_security_headers

  def authenticate_user!
    return become_active if logged_in? && adequate_scopes? && current_user.authorized_access_token?
    render_forbidden
  end

  private

  def render_forbidden
    render json: {
      message: "Unauthorized"
    }, status: :forbidden
  end

  def add_security_headers
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET"
    response.headers["Access-Control-Allow-Headers"] = "*"
    response.headers["Access-Control-Expose-Headers"] = "Total, Link, Per-Page"
  end
end
# rubocop:enable ClassAndModuleChildren
