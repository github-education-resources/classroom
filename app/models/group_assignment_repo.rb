# frozen_string_literal: true

class GroupAssignmentRepo < ApplicationRecord
  include GitHubPlan
  include GitHubRepoable
  include Nameable
  include AssignmentRepoable

  update_index("group_assignment_repo#group_assignment_repo") { self }

  enum configuration_state: %i[not_configured configuring configured]

  belongs_to :group
  belongs_to :group_assignment
  alias assignment group_assignment

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :group_assignment

  has_many :repo_accesses, through: :group

  validates :group_assignment, presence: true

  validates :group, presence: true
  validates :group, uniqueness: { scope: :group_assignment }

  before_validation(on: :create) do
    if organization
      create_github_repository
      delete_github_repository_on_failure do
        push_starter_code
        add_team_to_github_repository
      end
    end
  end

  before_destroy :silently_destroy_github_repository

  delegate :creator, :starter_code_repo_id, to: :group_assignment
  delegate :github_team_id,                 to: :group
  delegate :default_branch, :commits,       to: :github_repository

  def github_team
    return NullGitHubTeam.new if group.nil?

    @github_team ||= group.github_team
  end

  def repo_name
    @repo_name ||= generate_github_repo_name
  end

  private

  delegate :slug, to: :group_assignment

  def name
    @name ||= group.github_team.slug_no_cache
  end
end
