class GroupDecorator < Draper::Decorator
  delegate_all

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
