# frozen_string_literal: true

class AssignmentInvitation < ApplicationRecord
  include ShortKey

  default_scope { where(deleted_at: nil) }

  update_index("stafftools#assignment_invitation") { self }

  belongs_to :assignment

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
  def redeem_for(invitee)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?

    return AssignmentRepo::Creator::Result.failed("Invitations for this assignment have been disabled.") unless enabled?

    AssignmentRepo::Creator.perform(assignment: assignment, user: invitee)
  end

  def to_param
    key
  end

  def enabled?
    assignment.invitations_enabled?
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
