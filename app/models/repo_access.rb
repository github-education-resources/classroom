class RepoAccess < ActiveRecord::Base
  include GitHubTeamable

  belongs_to :user
  belongs_to :organization

  has_and_belongs_to_many :groups

  validates :github_team_id, presence:   true
  validates :github_team_id, uniqueness: true

  validates :organization, presence: true
  validates :organization, uniqueness: { scope: :user }

  validates :user, presence: true
  validates :user, uniqueness: { scope: :organization }

  before_validation(on: :create) do
    add_member_to_github_team if organization
  end

  private

  # Internal
  #
  def add_member_to_github_team
    github_team = GitHubTeam.new(organization.github_client, github_team_id)
    github_team.add_team_membership(user.github_login)

    users_github_organization = GitHubOrganization.new(user.github_client, organization.github_id)
    users_github_organization.accept_membership
  end

  # Internal
  #
  def title
    "Team #{organization.repo_accesses.count + 1}"
  end
end
