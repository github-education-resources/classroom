class GroupAssignmentRepo < ActiveRecord::Base
  include GitHubPlan
  include GitHubRepoable

  update_index('stafftools#group_assignment_repo') { self }

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :group_assignment

  has_many :repo_accesses, through: :group

  belongs_to :group
  belongs_to :group_assignment

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :group_assignment, presence: true

  validates :group, presence: true
  validates :group, uniqueness: { scope: :group_assignment }

  before_validation(on: :create) do
    if organization
      create_github_repository
      push_starter_code
      add_team_to_github_repository
    end
  end

  before_destroy :silently_destroy_github_repository

  delegate :github_team, :github_team_id,                   to: :group
  delegate :creator, :starter_code_repo_id, :starter_code?, to: :group_assignment

  def disabled?
    return @disabled if @disabled
    @disabled = (github_repository.disabled? || github_team.disabled?)
  end

  def private?
    !group_assignment.public_repo?
  end

  def repo_name
    headers     = { headers: GitHub::APIHeaders.no_cache_no_store }
    github_team = GitHubTeam.new(id: github_team_id, access_token: creator.access_token).team(headers)

    "#{group_assignment.slug}-#{github_team.slug}"
  end
end
