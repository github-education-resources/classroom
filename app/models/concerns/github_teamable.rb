module GitHubTeamable
  extend ActiveSupport::Concern

  delegate :github_organization, to: :organization

  def github_team
    return unless github_team_id.present?
    @github_team ||= GitHubTeam.new(id: github_team_id, access_token: organization.access_token)
  end

  def github_team_url
    "https://github.com/orgs/#{github_organization.login}/teams/#{github_team.slug}"
  end

  def create_github_team
    github_team = github_organization.create_team(name: title)
    self.github_team_id = github_team.id
  end

  def destroy_github_team
    return true unless github_team_id.present?
    github_organization.delete_team(github_team: github_team)
  end

  def silently_destroy_github_team
    destroy_github_team
    true # Destroy ActiveRecord object even if we fail to delete the team
  end
end
