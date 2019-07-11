# frozen_string_literal: true

class AssignmentRepo < ApplicationRecord
  include AssignmentRepoable
  include PgSearch

  pg_search_scope(
    :search,
    against: %i(
      id
      github_repo_id
    ),
    using: {
      tsearch: {
        dictionary: "english",
      }
    }
  )

  # TODO: remove this enum (dead code)
  enum configuration_state: %i[not_configured configuring configured]

  belongs_to :assignment
  belongs_to :repo_access, optional: true
  belongs_to :user

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  validates :assignment, presence: true

  validate :assignment_user_key_uniqueness

  delegate :creator, :starter_code_repo_id, to: :assignment
  delegate :github_user,                    to: :user
  delegate :default_branch, :commits,       to: :github_repository
  delegate :github_team_id,                 to: :repo_access, allow_nil: true

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

  # Internal: Validate uniqueness of <user, assignment> key.
  # Only runs the validation on new records.
  #
  def assignment_user_key_uniqueness
    return if persisted?
    return unless AssignmentRepo.find_by(user: user, assignment: assignment)
    errors.add(:assignment, "Should only have one assignment repository for each user-assignment combination")
  end
end
