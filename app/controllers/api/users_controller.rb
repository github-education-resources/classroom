# frozen_string_literal: true

module API
  class UsersController < API::ApplicationController
    include ActionController::Serialization

    def authenticated_user
      render json: current_user
    end
  end
end
