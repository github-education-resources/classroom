# frozen_string_literal: true

module Stafftools
  class GroupsController < StafftoolsController
    before_action :set_group

    def show; end

    def destroy
      grouping = @group.grouping

      if @group.destroy
        flash[:success] = 'Group successfully destroyed'
        redirect_to stafftools_grouping_path(grouping.id)
      else
        flash[:error] = 'Could not delete group'
        render :show
      end
    end

    private

    def set_group
      @group = Group.find_by!(id: params[:id])
    end
  end
end
