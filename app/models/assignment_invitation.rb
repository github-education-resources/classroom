# frozen_string_literal: true

class AssignmentInvitation < ApplicationRecord
  include ShortKey

  default_scope { where(deleted_at: nil) }

  update_index("stafftools#assignment_invitation") { self }

  belongs_to :assignment

  has_many :invite_statuses
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
  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def redeem_for(invitee, import_resiliency: false)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?

    return AssignmentRepo::Creator::Result.failed("Invitations for this assignment have been disabled.") unless enabled?

    status(invitee).accepted!
    if import_resiliency
      AssignmentRepo::Creator::Result.pending
    else
      AssignmentRepo::Creator.perform(assignment: assignment, user: invitee)
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def to_param
    key
  end

  def enabled?
    assignment.invitations_enabled?
  end

  def errored?
    errored_creating_repo? || errored_importing_starter_code?
  end

  def status(user)
    invite_statuses.find_by_user_id(user.id) || InviteStatus.create(user_id: user.id, assignment_invitation_id: self.id)
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
