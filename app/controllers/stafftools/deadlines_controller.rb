# frozen_string_literal: true

module Stafftools
  class DeadlinesController < StafftoolsController
    before_action :set_deadline

    def show; end

    private

    def set_deadline
      @deadline = Deadline.find_by!(id: params[:id])
    end
  end
end
