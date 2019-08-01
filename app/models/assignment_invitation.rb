# frozen_string_literal: true

class AssignmentInvitation < ApplicationRecord
  include ShortKey
  include StafftoolsSearchable

  define_pg_search(columns: %i[id key])

  default_scope { where(deleted_at: nil) }

  belongs_to :assignment

  has_many :invite_statuses, dependent: :destroy
  has_many :users, through: :invite_statuses
  has_one :organization, through: :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  validates :short_key, uniqueness: true, allow_nil: true

  after_initialize :assign_key

  delegate :title, to: :assignment

  # Public: Redeem an AssignmentInvtiation for a User invitee.
  #
  # Returns a AssignmentRepo::Creator::Result.
  #
  # rubocop:disable AbcSize
  def redeem_for(invitee)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      creator_result_class.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return creator_result_class.success(assignment_repo) if assignment_repo.present?

    return creator_result_class.failed("Invitations for this assignment have been disabled.") unless enabled?

    creator_result_class.pending
  end
  # rubocop:enable AbcSize

  def to_param
    key
  end

  def enabled?
    assignment.invitations_enabled?
  end

  def status(user)
    invite_status = invite_statuses.find_by(user: user)
    return invite_status if invite_status.present?

    InviteStatus.create(user: user, assignment_invitation: self)
  end

  protected

  # Provides the correct Result class
  # Both classes have essentially same functionality but,
  # Using them based on feature flag for consistency
  # TODO: remove this method when we remove creators
  def creator_result_class
    if GitHubClassroom.flipper[:unified_repo_creators].enabled?
      CreateGitHubRepoService::Result
    else
      AssignmentRepo::Creator::Result
    end
  end

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
