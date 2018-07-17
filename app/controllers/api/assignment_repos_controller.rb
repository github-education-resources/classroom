# frozen_string_literal: true

module API
  class AssignmentReposController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment

    def index
      repos = AssignmentRepo.where(assignment: @assignment)
      paginate json: repos
    end

    private

    def set_assignment
      @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:assignment_id])
    end
  end
end
