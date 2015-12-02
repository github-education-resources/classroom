module Stafftools
  class GroupAssignmentReposController < StafftoolsController
    before_action :set_group_assignment_repo

    def show
    end

    private

    def set_group_assignment_repo
      @group_assignment_repo = GroupAssignmentRepo.find_by(id: params[:id])
    end
  end
end
