# frozen_string_literal: true

module API
  class AssignmentReposController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment

    def index
      repos = AssignmentRepo.where(assignment: @assignment).order(:id)
      paginate json: repos
    end

    def clone_url
      repo = AssignmentRepo.where(assignment: @assignment, id: params[:assignment_repo_id]).first
      render json: {
        temp_clone_url: repo.github_repository.temp_clone_url
      }
    end

    private

    def set_assignment
      @assignment = @organization.assignments.find_by!(slug: params[:assignment_id])
    end
  end
end
