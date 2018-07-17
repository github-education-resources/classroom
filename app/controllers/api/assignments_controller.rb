# frozen_string_literal: true

module API
  class AssignmentsController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment, except: :index

    def index
      paginate json: @organization.assignments
    end

    def show
      render json: @assignment
    end

    private

    def set_assignment
      @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
    end
  end
end
