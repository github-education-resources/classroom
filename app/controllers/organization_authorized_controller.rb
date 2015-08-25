class OrganizationAuthorizedController < ApplicationController
  before_action :set_organization, :authorize_organization_access

  decorates_assigned :organization

  private

  def authorize_organization_access
    not_found if !@organization.users.include?(current_user) && current_user.staff?
  end

  def not_found
    fail ActionController::RoutingError, 'Not Found'
  end

  def set_organization
    @organization = Organization.friendly.find(params[:organization_id])
  end
end
