# frozen_string_literal: true
class GroupingsController < ApplicationController
  include OrganizationAuthorization

  before_action :set_grouping
  before_action :ensure_team_management_flipper_is_enabled?

  def show
  end

  private

  def set_grouping
    @grouping = Grouping.find_by!(slug: params[:id])
  end
end
