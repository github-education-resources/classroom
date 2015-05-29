class Github::Team
  attr_reader :id, :name

  def initialize(github_client, org_id)
    @github_client = github_client
    @org_id        = org_id
  end

  def find_or_create_team(team_id, team_name)
    if team = @github_client.team(team_id)
      set_team_attributes(team.id, team.name)
    elsif team = @github_client.create_team(@org_id, { name: team_name, permission: 'push' })
      set_team_attributes(team.id, team.name)
    else
      return Github::Null::Team.new
    end

    self
  end

  private

  def set_team_attributes(id, name)
    @id   = id
    @name = name
  end
end
