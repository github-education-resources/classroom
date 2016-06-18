# frozen_string_literal: true
class GroupingsController < ApplicationController
  include OrganizationAuthorization

  before_action :set_grouping

  def show
  end

  private

  def set_grouping
    @grouping = Grouping.find_by!(id: params[:id])
  end
end
