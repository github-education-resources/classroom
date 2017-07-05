class RostersController < ApplicationController
  before_action :set_organization

  def new; end

  def create

  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end
end
