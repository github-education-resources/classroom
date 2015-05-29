class Inviter
  def initialize(user, organization, team_id, title)
    @user = user
    @organization = organization
    @team_id = team_id
    @title = title
  end

  def create_invitation
    team = find_or_create_github_team
    invitation = @organization.build_invitation(title:   team.name,
                                                team_id: team.id,
                                                user_id: @user.id)
  end

private

  def find_or_create_github_team
    if team = @user.github_client.team(@team_id)
      team
    else
      begin
        @user.github_client.create_team(@organization.github_id, {name: @title, permission: 'push'})
      rescue
        NullTeam.new
      end
    end
  end

  class NullTeam
    attr_reader :name, :id
  end
end
