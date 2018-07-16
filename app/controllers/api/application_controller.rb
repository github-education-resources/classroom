# frozen_string_literal: true

class API::ApplicationController < ApplicationController
  include Rails::Pagination
  
  def authenticate_user!
    return become_active if logged_in? && adequate_scopes?
    render_forbidden()
  end

  def render_forbidden()
    render json: {
      message: "Unauthorized"
    }, status: :forbidden
  end

end
