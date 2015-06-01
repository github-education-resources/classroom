class Inviter
  def initialize(creator, organization, team_id, team_title)
    @creator      = creator
    @organization = organization
    @team_id      = team_id
    @team_title   = team_title
  end

  def create_invitation
    team = GitHubTeam.find_or_create_team(@creator.github_client, @organization.github_id, @team_id, @team_title)
    @organization.build_invitation(team_id: team.id, title: team.name, user_id: @creator.id)
  end
end
