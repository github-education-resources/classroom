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
      if repo.present?
        render json: {
          temp_clone_url: repo.github_repository.temp_clone_url
        }
      else
        render json: { "error": "not_found" }, status: :not_found
      end
    end

    private

    def set_assignment
      @assignment = @organization.assignments.find_by!(slug: params[:assignment_id])
    end
  end
end
