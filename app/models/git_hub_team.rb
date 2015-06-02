class GitHubTeam
  attr_reader :id, :name

  def initialize(id, name)
    @id   = id
    @name = name
  end

  def self.find_or_create_team(github_client, org_id, team_id, team_name)
    if team = github_client.team(team_id)
      GitHubTeam.new(team.id, team.name)
    elsif team = github_client.create_team(org_id, { name: team_name, permission: 'push' })
      GitHubTeam.new(team.id, team.name)
    else
      NullGitHubTeam.new
    end
  end
end
