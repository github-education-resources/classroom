class OrganizationDecorator < Draper::Decorator
  delegate_all

  def avatar_url(size)
    "https://avatars.githubusercontent.com/u/#{github_id}?v=3&size=#{size}"
  end

  def geo_pattern_data_uri
    @geo_pattern_data_uri ||= GeoPattern.generate(github_id, color: '#5fb27b').to_data_uri
  end

  def github_url
    github_organization.html_url
  end

  def github_team_invitations_url
    "https://github.com/orgs/#{login}/invitations/new"
  end

  def login
    github_organization.login
  end

  private

  def github_organization
    @github_organization ||= GitHubOrganization.new(github_client, github_id).organization
  rescue GitHub::NotFound
    NullGitHubOrganization.new
  end
end
