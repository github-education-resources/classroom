class GitHubTeam
  attr_reader :id, :name

  def initialize(creator, id, name)
    @creator = creator
    @id      = id
    @name    = name
  end

  def add_user_to_team(user)
    login = user.github_client.user.login
    @creator.github_client.add_team_membership(@id, login)
  end

  def self.create_team(creator, org_github_id, team_name)
    if (team = creator.github_client.create_team(org_github_id, name: team_name, permission: 'push'))
      GitHubTeam.new(creator, team.id, team.name)
    else
      NullGitHubTeam.new
    end
  end
end
