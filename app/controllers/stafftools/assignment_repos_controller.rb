module Stafftools
  class AssignmentReposController < StafftoolsController
    before_action :set_assignment_repo

    def show
    end

    def edit
    end

    def update
    end

    def destroy
    end

    private

    def set_assignment_repo
      @assignment_repo = AssignmentRepo.find_by(id: params[:id])
    end
  end
end
