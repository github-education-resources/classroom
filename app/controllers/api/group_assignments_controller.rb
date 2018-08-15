# frozen_string_literal: true

module API
  class GroupAssignmentsController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment, only: :show

    def index
      paginate json: @organization.group_assignments
    end

    def show
      render json: @group_assignment
    end

    private

    def set_assignment
      @group_assignment = @organization.group_assignments
        .includes(:group_assignment_invitation)
        .find_by!(slug: params[:id])
    end
  end
end
