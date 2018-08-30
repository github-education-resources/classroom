# frozen_string_literal: true

class GroupAssignmentRepo < ApplicationRecord
  include GitHubPlan
  include GitHubRepoable
  include Nameable

  update_index("stafftools#group_assignment_repo") { self }

  enum configuration_state: %i[not_configured configuring configured]

  belongs_to :group
  belongs_to :group_assignment
  alias assignment group_assignment

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :group_assignment

  has_many :repo_accesses, through: :group

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
  delegate :default_branch, :commits,       to: :github_repository

  # TODO: Move to a view model
  def disabled?
    @disabled ||= !github_repository.on_github? || !github_team.on_github?
  end

  def github_repository
    @github_repository ||= GitHubRepository.new(organization.github_client, github_repo_id)
  end

  def github_team
    @github_team ||= group.github_team
  end

  def private?
    !group_assignment.public_repo?
  end

  def repo_name
    @repo_name ||= generate_github_repo_name
  end

  def import_status
    return "No starter code provided" unless group_assignment.starter_code?

    github_repository.import_progress.status.humanize
  end

  private

  delegate :slug, to: :group_assignment

  def name
    @name ||= group.github_team.slug_no_cache
  end
end
