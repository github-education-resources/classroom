# frozen_string_literal: true

class AssignmentInvitation < ApplicationRecord
  include ShortKey

  enum status: %i[ unaccepted accepted creating_repo importing_starter_code completed errored ]

  default_scope { where(deleted_at: nil) }

  update_index("stafftools#assignment_invitation") { self }

  belongs_to :assignment

  has_one :organization, through: :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  validates :short_key, uniqueness: true, allow_nil: true

  after_initialize :assign_key

  after_initialize :set_defaults, unless: :persisted?

  delegate :title, to: :assignment

  # Public: Redeem an AssignmentInvtiation for a User invitee.
  #
  # Returns a AssignmentRepo::Creator::Result.
  def redeem_for(invitee, import_resiliency: false)
    accepted!
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?

    return AssignmentRepo::Creator::Result.failed("Invitations for this assignment have been disabled.") unless enabled?

    if import_resiliency
      AssignmentRepo::Creator::Result.pending()
    else
      AssignmentRepo::Creator.perform(assignment: assignment, user: invitee)
    end
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

  def set_defaults
    self.status ||= :unaccepted
  end
end
