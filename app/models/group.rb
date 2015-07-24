class Group < ActiveRecord::Base
  include GitHubTeamable

  has_one :organization, through: :grouping

  belongs_to :grouping

  has_and_belongs_to_many :repo_accesses, before_add: :add_member_to_github_team, unless: :new_record?,
                                          before_remove: :remove_from_github_team

  validates :github_team_id, presence: true
  validates :github_team_id, uniqueness: true

  validates :grouping, presence: true

  validates :title, presence: true

  private

  # Internal
  #
  def add_member_to_github_team(repo_access)
    github_team.add_team_membership(repo_access.user.github_login)
  end

  # Internal
  #
  def remove_from_github_team(repo_access)
    github_team.remove_team_membership(repo_access.user.github_login)
  end

  # Internal
  #
  def github_team
    @github_team ||= GitHubTeam.new(organization.github_client, github_team_id)
  end
end
