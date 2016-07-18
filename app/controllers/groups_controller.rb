# frozen_string_literal: true
class GroupsController < ApplicationController
  include OrganizationAuthorization

  before_action :ensure_team_management_flipper_is_enabled
  before_action :set_group

  def show
  end

  private

  def set_group
    @grouping = Group.find_by!(slug: params[:id])
  end
end