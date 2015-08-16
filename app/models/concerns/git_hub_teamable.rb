module GitHubTeamable
  extend ActiveSupport::Concern

  included do
    before_validation(on: :create) do
      create_github_team if organization
    end

    before_destroy :destroy_github_team
  end

  # Public: Create a GitHub team
  # Return the GitHub team id
  def create_github_team
    github_team = github_organization.create_team(title)
    self.github_team_id = github_team.id
  end

  # Public: Destroy a GitHub team
  # Returns true even if the team was not destroyed, this
  # is a fail safe incase the team doesn't exist.
  def destroy_github_team
    github_organization.delete_team(github_team_id)
    true
  end

  # Internal: Find or create the GitHub Organization
  # Returns the GitHubOrganization
  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end
end
