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

    # rubocop:disable MethodLength
    def clone_url
      repo = GroupAssignmentRepo.where(
        group_assignment: @group_assignment,
        id: params[:group_assignment_repo_id]
      ).first

      if repo.present?
        render json: {
          temp_clone_url: repo.github_repository.temp_clone_url
        }
      else
        render json: { "error": "not_found" }, status: :not_found
      end
    end
    # rubocop:enable MethodLength

    private

    def set_assignment
      @group_assignment = @organization.group_assignments.find_by!(slug: params[:group_assignment_id])
    end
  end
end
