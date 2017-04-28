# frozen_string_literal: true

module Stafftools
  class GroupsController < StafftoolsController
    before_action :set_group

    def show; end

    private

    def set_group
      @group = Group.find_by!(id: params[:id])
    end
  end
end
