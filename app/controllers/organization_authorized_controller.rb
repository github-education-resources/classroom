class OrganizationAuthorizedController < ApplicationController
  before_action :set_organization
  before_action :ensure_permission

  after_action :verify_authorized

  private

  def ensure_permission
    authorize @organization
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
