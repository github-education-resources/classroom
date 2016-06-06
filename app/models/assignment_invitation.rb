# frozen_string_literal: true
class AssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  update_index('stafftools#assignment_invitation') { self }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem_for(invitee, identifier_value = nil)
    create_student_identifier(invitee, identifier_value)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return assignment_repo if assignment_repo.present?
    end

    AssignmentRepo.find_or_create_by!(assignment: assignment, user: invitee)
  end

  def create_student_identifier(invitee, identifier_value)
    return unless assignment.student_identifier_type.present? && identifier_value.present?
    StudentIdentifier.find_or_create_by!(organization: organization,
                                         user: invitee,
                                         student_identifier_type: assignment.student_identifier_type,
                                         value: identifier_value)
  end

  def title
    assignment.title
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
