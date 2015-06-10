class RepoAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates_presence_of   :github_team_id
  validates_uniqueness_of :github_team_id

  def create_github_team(org_owner, team_name)
    team = GitHubTeam.find_or_create_team(org_owner.github_client, self.organization.github_id, nil, team_name)

    org_owner.github_client.add_team_membership(team.id, user.github_client.user.login)

    self.github_team_id = team.id
  end
end
