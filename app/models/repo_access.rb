class RepoAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :github_team_id, presence:   true
  validates :github_team_id, uniqueness: true

  def create_github_team(org_owner, team_name)
    team = GitHubTeam.find_or_create_team(org_owner.github_client, organization.github_id, nil, team_name)

    org_owner.github_client.add_team_membership(team.id, user.github_client.user.login)

    self.github_team_id = team.id
  end
end
