class GroupDecorator < Draper::Decorator
  delegate_all

  def name
    github_team.name
  end

  private

  def github_team
    @github_team ||= GitHubTeam.new(organization.github_client, github_team_id).team
  end
end
