module GitHubTeamable
  extend ActiveSupport::Concern

  included do
    before_validation(on: :create) do
      create_github_team if organization
    end

    before_destroy :destroy_github_team
  end

  # Public
  #
  def create_github_team
    github_team = github_organization.create_team(title)
    self.github_team_id = github_team.id
  end

  # Public
  #
  def destroy_github_team
    github_organization.delete_team(github_team_id)
    true # Destroy ActiveRecord object even if we fail to delete the team
  end

  # Internal
  #
  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end
end
