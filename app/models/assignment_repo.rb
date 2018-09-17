# frozen_string_literal: true

class AssignmentRepo < ApplicationRecord
  update_index("stafftools#assignment_repo") { self }

  enum configuration_state: %i[not_configured configuring configured]

  belongs_to :assignment
  belongs_to :repo_access, optional: true
  belongs_to :user

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  # TODO: Remove this dependency from the model.
  before_destroy :silently_destroy_github_repository

  delegate :creator, :starter_code_repo_id, to: :assignment
  delegate :github_user,                    to: :user
  delegate :default_branch, :commits,       to: :github_repository

  # This should really be in a view model
  # but it'll live here for now.
  def disabled?
    @disabled ||= !github_repository.on_github? || !github_user.on_github?
  end

  def private?
    !assignment.public_repo?
  end

  def github_team_id
    repo_access.present? ? repo_access.github_team_id : nil
  end

  def github_repository
    @github_repository ||= GitHubRepository.new(organization.github_client, github_repo_id)
  end

  def import_status
    return "No starter code provided" unless assignment.starter_code?

    github_repository.import_progress.status.humanize
  end

  # Public: This method is used for legacy purposes
  # until we can get the transition finally completed
  #
  # NOTE: We used to create one person teams for Assignments,
  # however when the new organization permissions came out
  # https://github.com/blog/2020-improved-organization-permissions
  # we were able to move these students over to being an outside collaborator
  # so when we deleted the AssignmentRepo we would remove the student as well.
  #
  # Returns the User associated with the AssignmentRepo
  alias original_user user
  def user
    original_user || repo_access.user
  end

  private

  # Internal: Attempt to destroy the GitHub repository.
  #
  # Returns true.
  def silently_destroy_github_repository
    return true if organization.blank?

    organization.github_organization.delete_repository(github_repo_id)
    true
  rescue GitHub::Error
    true
  end
end
