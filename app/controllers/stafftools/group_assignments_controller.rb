# frozen_string_literal: true

module Stafftools
  class GroupAssignmentsController < StafftoolsController
    before_action :set_group_assignment

    def show; end

    private

    def set_group_assignment
      @group_assignment = GroupAssignment.find_by!(id: params[:id])
    end
  end
end
