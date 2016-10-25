# frozen_string_literal: true
module Stafftools
  class AssignmentReposController < StafftoolsController
    before_action :set_assignment_repo

    def show
    end

    def list_item
      respond_to { |format| format.html { render layout: false } }
    end

    private

    def set_assignment_repo
      @assignment_repo = AssignmentRepo.includes(:assignment, :organization).find_by!(id: params[:id])
    end
  end
end
