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

  # Public
  #
  def creator
    group_assignment.creator
  end

  # Public
  #
  def private?
    !group_assignment.public_repo?
  end

  # Public
  #
  def github_team_id
    group.github_team_id
  end

  # Public
  #
  def repo_name
    github_team = GitHubTeam.new(creator.github_client, github_team_id).team
    "#{group_assignment.slug}-#{github_team.slug}"
  end

  # Public
  #
  def starter_code_repo_id
    group_assignment.starter_code_repo_id
  end
end
