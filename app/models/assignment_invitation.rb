# frozen_string_literal: true

class AssignmentInvitation < ApplicationRecord
  include ShortKey
  include StafftoolsSearchable

  INVITATIONS_DISABLED = "Invitations for this assignment have been disabled."
  INVITATIONS_DISABLED_ARCHIVED = "Invitations for this assignment are disabled because the classroom is archived."

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
  # Returns a CreateGitHubRepoService::Result.
  #
  def redeem_for(invitee)
    return reason_for_disabled_invitations unless enabled?

    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      CreateGitHubRepoService::Result.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return CreateGitHubRepoService::Result.success(assignment_repo) if assignment_repo.present?

    CreateGitHubRepoService::Result.pending
  end

  def to_param
    key
  end

  def enabled?
    assignment.invitations_enabled? && !assignment.organization.archived?
  end

  def status(user)
    invite_status = invite_statuses.find_by(user: user)
    return invite_status if invite_status.present?

    InviteStatus.create(user: user, assignment_invitation: self)
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  def reason_for_disabled_invitations
    return CreateGitHubRepoService::Result.failed(INVITATIONS_DISABLED) unless assignment.invitations_enabled?
    return CreateGitHubRepoService::Result.failed(INVITATIONS_DISABLED_ARCHIVED) if assignment.organization.archived?
  end
end
