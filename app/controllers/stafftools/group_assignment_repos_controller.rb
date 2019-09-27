# frozen_string_literal: true

module Stafftools
  class GroupAssignmentReposController < StafftoolsController
    before_action :set_group_assignment_repo

    def show; end

    def destroy
      group_assignment = @group_assignment_repo.group_assignment

      if @group_assignment_repo.destroy
        flash[:success] = "Group assignment repository was destroyed"
        redirect_to stafftools_group_assignment_path(group_assignment.id)
      else
        flash[:error] = "Could not delete group assignment repository"
        render :show
      end
    end

    private

    def set_group_assignment_repo
      @group_assignment_repo = GroupAssignmentRepo.find_by!(id: params[:id])
    end
  end
end
