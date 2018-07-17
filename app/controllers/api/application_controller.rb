# frozen_string_literal: true

class API::ApplicationController < ApplicationController
  include Rails::Pagination
  
  def authenticate_user!
    return become_active if logged_in? && adequate_scopes? && current_user.authorized_access_token?
    return_forbidden()
  end

  def return_forbidden()
    render json: {
      message: "Unauthorized"
    }, status: :forbidden
  end

end
