class GitHubTeam
  attr_reader :id, :name

  def initialize(github_client, org_id, id=nil, name=nil)
    @github_client = github_client
    @org_id        = org_id
    @id            = id
    @name          = name
  end

  def find_or_create_team(team_id, team_name)
    if team = @github_client.team(team_id)
      GitHubTeam.new(@github_client, @org_id, team.id, team.name)
    elsif team = @github_client.create_team(@org_id, { name: team_name, permission: 'push' })
      GitHubTeam.new(@github_client, @org_id, team.id, team.name)
    else
      NullGitHubTeam.new
    end
  end
end
