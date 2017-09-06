# frozen_string_literal: true

module Orgs
  class AssignmentReposController < Orgs::Controller
    layout false

    def show
      @assignment_repo = AssignmentRepo.includes(:user).find_by!(id: params[:id], assignment: current_assignment)
    end

    private

    def current_assignment
      return @current_assignment if defined?(@current_assignment)
      @current_assignment = current_organization.assignments.find_by(slug: params[:assignment_id])
    end
  end
end
