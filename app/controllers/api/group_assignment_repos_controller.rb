# frozen_string_literal: true

module API
  class GroupAssignmentReposController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment

    def index
      repos = GroupAssignmentRepo.where(group_assignment: @group_assignment)
      paginate json: repos
    end

    private

    def set_assignment
      @group_assignment = @organization.group_assignments.find_by!(slug: params[:group_assignment_id])
    end
  end
end
