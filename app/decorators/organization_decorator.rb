class OrganizationDecorator < Draper::Decorator
  delegate_all

  def github_url
    github_organization.html_url
  end

  def github_team_invitations_url
    "https://github.com/orgs/#{github_organization.login}/invitations/new"
  end

  def login
    github_organization.login
  end

  private

  def github_organization
    @github_organization ||= GitHubOrganization.new(github_client, github_id).organization
  end
end
