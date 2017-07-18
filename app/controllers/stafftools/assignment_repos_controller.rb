# frozen_string_literal: true

module Stafftools
  class AssignmentReposController < StafftoolsController
    before_action :set_assignment_repo

    def show; end

    def destroy
      assignment = @assignment_repo.assignment

      if @assignment_repo.destroy
        flash[:success] = "Assignment repository was destroyed"
        redirect_to stafftools_assignment_path(assignment.id)
      else
        flash[:error] = "Could not delete assignment repository"
        render :show
      end
    end

    private

    def set_assignment_repo
      @assignment_repo = AssignmentRepo.find_by!(id: params[:id])
    end
  end
end
