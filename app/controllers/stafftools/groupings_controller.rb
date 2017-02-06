# frozen_string_literal: true
module Stafftools
  class GroupingsController < StafftoolsController
    before_action :set_grouping

    def show; end

    def destroy
      org = @grouping.organization

      GroupAssignment.where(grouping: @grouping).destroy_all

      if @grouping.destroy
        flash[:success] = 'Grouping was destroyed'
        redirect_to stafftools_organization_path(org.id)
      else
        flash[:error] = 'Grouping was not destroyed'
        render :show
      end
    end

    private

    def set_grouping
      @grouping = Grouping.find_by!(id: params[:id])
    end
  end
end
