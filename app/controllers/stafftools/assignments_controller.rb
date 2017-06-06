# frozen_string_literal: true

module Stafftools
  class AssignmentsController < StafftoolsController
    before_action :set_assignment

    def show; end

    private

    def set_assignment
      @assignment = Assignment.find_by!(id: params[:id])
    end
  end
end
