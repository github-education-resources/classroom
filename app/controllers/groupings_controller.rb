# frozen_string_literal: true
class GroupingsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled
  before_action :set_grouping

  def show
  end

  def edit
    not_found unless Classroom.flipper[:team_management].enabled? current_user
  end

  def update
    not_found unless Classroom.flipper[:team_management].enabled? current_user
    if @grouping.update_attributes(update_grouping_params)
      flash[:success] = "Set of teams \"#{@grouping.title}\" updated"
      redirect_to settings_teams_organization_path(@organization)
    else
      render :edit
    end
  end

  private

  def set_grouping
    @grouping = Grouping.find_by!(slug: params[:id])
  end

  def update_grouping_params
    params
      .require(:grouping)
      .permit(:title)
  end
end
