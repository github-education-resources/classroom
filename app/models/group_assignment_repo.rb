# frozen_string_literal: true
class GroupAssignmentRepo < ActiveRecord::Base
  include GitHubPlan
  include GitHubRepoable
  include Nameable

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

  delegate :creator, :starter_code_repo_id, to: :group_assignment
  delegate :github_team_id,                 to: :group

  def private?
    !group_assignment.public_repo?
  end

  def repo_name
    @repo_name ||= generate_github_repo_name
  end

  private

  delegate :slug, to: :group_assignment

  def name
    @name ||= group.github_team.slug(headers: GitHub::APIHeaders.no_cache_no_store)
  end
end
