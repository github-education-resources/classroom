class GroupDecorator < Draper::Decorator
  delegate_all

  def github_team_url
    "https://github.com/orgs/#{github_team.organization.login}/teams/#{github_team.slug}"
  end

  def name
    github_team.name
  end

  def slug
    github_team.slug
  end

  private

  def github_team
    @github_team ||= GitHubTeam.new(organization.github_client, github_team_id).team
  rescue GitHub::NotFound
    NullGitHubTeam.new
  end
end
