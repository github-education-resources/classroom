# frozen_string_literal: true

module API
  class GroupAssignmentReposController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment

    def index
      repos = GroupAssignmentRepo.where(group_assignment: @group_assignment).order(:id)
      paginate json: repos
    end

    def clone_url
      repo = GroupAssignmentRepo.where(
        group_assignment: @group_assignment,
        id: params[:group_assignment_repo_id]
      ).first
      render json: {
        temp_clone_url: repo.github_repository.temp_clone_url
      }
    end

    private

    def set_assignment
      @group_assignment = @organization.group_assignments.find_by!(slug: params[:group_assignment_id])
    end
  end
end
