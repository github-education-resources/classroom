# frozen_string_literal: true

class Group < ApplicationRecord
  include GitHubTeamable
  include Sluggable

  update_index("group#group") { self }

  belongs_to :grouping

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :grouping

  has_and_belongs_to_many :repo_accesses,
    before_add: :add_member_to_github_team, unless: :new_record?,
    before_remove: :remove_from_github_team

  has_many :users, through: :repo_accesses
  has_many :group_invite_statuses, dependent: :destroy
  has_many :group_assignment_repos
  has_many :assignment_repos

  validates :github_team_id, presence: true
  validates :github_team_id, uniqueness: true

  validates :grouping, presence: true

  validates :title, presence: true
  validates :title, length: { maximum: 39 }
  validates :title, no_emoji: true, on: :create

  validates :slug, uniqueness: { scope: :grouping }

  before_destroy :silently_destroy_github_team

  def github_team
    @github_team ||= GitHubTeam.new(organization.github_client, github_team_id)
  end

  private

  def add_member_to_github_team(repo_access)
    github_team.add_team_membership(repo_access.user.github_user.login)
  end

  def remove_from_github_team(repo_access)
    github_team.remove_team_membership(repo_access.user.github_user.login)
  end
end
