# frozen_string_literal: true
class GroupingsController < ApplicationController
  include OrganizationAuthorization

  before_action :set_grouping
  before_action :ensure_flipper_is_enabled

  def show
  end

  private

  def ensure_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def set_grouping
    @grouping = Grouping.find_by!(slug: params[:id])
  end
end
