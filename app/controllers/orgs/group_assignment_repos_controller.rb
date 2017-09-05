# frozen_string_literal: true

module Orgs
  class GroupAssignmentReposController < Orgs::Controller
    layout false

    def show
      @group_assignment_repo = GroupAssignmentRepo.includes(:group).find_by!(
        id: params[:id],
        group_assignment: current_group_assignment
      )
    end

    private

    def current_group_assignment
      return @current_assignment if defined?(@current_assignment)
      @current_assignment = current_organization.group_assignments.find_by(slug: params[:group_assignment_id])
    end
  end
end
