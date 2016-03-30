module OrganizationAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :set_organization, :authorize_organization_access
  end

  def authorize_organization_access
    return if @organization.users.include?(current_user)

    begin
      github_organization.admin?(decorated_current_user.login) ? @organization.users << current_user : not_found
    rescue
      not_found
    end
  end

  private

  def github_organization
    @github_organization ||= GitHubOrganization.new(current_user.github_client, @organization.github_id)
  end

  def set_organization
    @organization = Organization.find_by!(id: params[:organization_id])
  rescue ActiveRecord::RecordNotFound
    @organization = Organization.find_by!(slug: params[:organization_id])
  end
end
