# frozen_string_literal: true

class GroupAssignmentRepo < ApplicationRecord
  include AssignmentRepoable
  include Sortable
  include PgSearch

  pg_search_scope(
    :search,
    against: %i[
      id
      github_repo_id
    ],
    using: {
      tsearch: {
        dictionary: "english"
      }
    }
  )

  enum configuration_state: %i[not_configured configuring configured]

  belongs_to :group
  belongs_to :group_assignment
  alias assignment group_assignment

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :group_assignment

  has_many :repo_accesses, through: :group

  validates :group_assignment, presence: true

  validates :group, presence: true
  validates :group, uniqueness: { scope: :group_assignment }

  delegate :creator, :starter_code_repo_id, to: :group_assignment
  delegate :github_team_id,                 to: :group
  delegate :default_branch, :commits,       to: :github_repository
  delegate :slug, to: :group_assignment

  scope :order_by_repo_created_at, ->(_context = nil) { order(:created_at) }
  scope :order_by_team_name, ->(_context = nil) { joins(:group).order("title asc") }

  def self.sort_modes
    {
      "Created at" => :order_by_repo_created_at,
      "Team name" => :order_by_team_name
    }
  end

  def github_team
    return NullGitHubTeam.new if group.nil?

    @github_team ||= group.github_team
  end
end
