class AssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem_for(invitee)
    repo_access = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    AssignmentRepo.find_or_create_by!(assignment: assignment, repo_access: repo_access)
  end

  def title
    assignment.title
  end

  # Public: Override the
  #
  # Returns the key as a String
  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
