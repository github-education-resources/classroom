# frozen_string_literal: true
class GroupingsController < ApplicationController
  include OrganizationAuthorization

  before_action :set_grouping

  def show
    not_found unless Classroom.flipper[:team_management].enabled? current_user
  end

  private

  def set_grouping
    @grouping = Grouping.find_by!(slug: params[:id])
  end
end
