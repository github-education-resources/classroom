# frozen_string_literal: true
module Stafftools
  class GroupsController < StafftoolsController
    before_action :set_group

    def show; end

    def destroy
      grouping = @group.grouping

      @group.destroy

      flash[:success] = 'Group was destroyed'
      redirect_to stafftools_grouping_path(grouping.id)
    end

    private

    def set_group
      @group = Group.find_by!(id: params[:id])
    end
  end
end
