class GroupDecorator < Draper::Decorator
  delegate_all

  def name
    github_team.name
  rescue GitHub::NotFound
    "Deleted team"
  end

  def slug
    github_team.slug
  rescue GitHub::NotFound
    'ghost'
  end

  private

  def github_team
    @github_team ||= GitHubTeam.new(organization.github_client, github_team_id).team
  end
end
