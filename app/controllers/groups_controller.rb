class GroupsController < ApplicationController
  before_action :set_grouping

  def create
    @group_creator = GroupCreator.new(current_user, @grouping.organization)

    respond_to do |format|
      if (@group = @group_creator.create_group(new_group_params))
        format.js
      else
        # error.js.erb
      end
    end
  end

  private

  def new_group_params
    params
      .require(:group)
      .permit(:title)
      .merge(grouping_id: @grouping.id)
  end

  def set_grouping
    @grouping = GroupAssignmentInvitation.find_by_key!(params[:key]).grouping
  end
end
