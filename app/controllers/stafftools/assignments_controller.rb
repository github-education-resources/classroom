module Stafftools
  class AssignmentsController < StafftoolsController
    before_action :set_assignment

    def show
    end

    def edit
    end

    def update
    end

    def destroy
    end

    private

    def set_assignment
      @assignment = Assignment.find_by(id: params[:id])
    end
  end
end
