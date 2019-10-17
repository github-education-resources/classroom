# frozen_string_literal: true

module OrganizationAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :set_organization, :authorize_organization_access
  end

  def authorize_organization_access
    return if @organization.users.include?(current_user)
    github_organization.admin?(current_user.github_user.login) ? @organization.users << current_user : not_found
  end

  private

  def github_organization
    @github_organization ||= GitHubOrganization.new(current_user.github_client, @organization.github_id)
  end

  def set_organization
    return @organization if defined?(@organization)

    organization_id = params[:organization_id] || params[:id]
    @organization = Organization.find_by!(slug: organization_id)
  end
end
