class OrganizationDecorator < Draper::Decorator
  delegate_all

  def geo_pattern_data_uri
    @geo_pattern_data_uri ||= GeoPattern.generate(title, color: '#5fb27b').to_data_uri
  end

  def github_url
    github_organization.html_url
  end

  def login
    github_organization.login
  end

  private

  def github_organization
    @github_organization ||= GitHubOrganization.new(github_client, github_id).organization
  end
end
