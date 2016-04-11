module GitHubTeamable
  extend ActiveSupport::Concern

  # Public
  #
  def create_github_team
    github_team = github_organization.create_team(title)
    self.github_team_id = github_team.id
  end

  # Public
  #
  def destroy_github_team
    return true unless github_team_id.present?
    github_organization.delete_team(github_team_id)
  end

  # Public
  #
  def silently_destroy_github_team
    destroy_github_team
    true # Destroy ActiveRecord object even if we fail to delete the team
  end

  # Internal
  #
  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end
end
