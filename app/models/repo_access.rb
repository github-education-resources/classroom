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
    if organization
      add_member_to_github_team
      accept_membership_to_organization
    end
  end

  private

  # Internal
  #
  def add_member_to_github_team
    github_team = GitHubTeam.new(organization.github_client, github_team_id)
    github_user = GitHubUser.new(user.github_client)

    github_team.add_team_membership(github_user.login)
  end

  # Interal
  #
  def accept_membership_to_organization
    users_github_organization = GitHubOrganization.new(user.github_client, organization.github_id)
    users_github_organization.accept_membership
  end

  # Internal
  #
  def title
    GitHubUser.new(user.github_client).login
  end
end
