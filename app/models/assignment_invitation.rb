class AssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem_for(invitee)
    repo_access                  = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    assignment_repo              = AssignmentRepo.find_or_create_by!(assignment: assignment, repo_access: repo_access)
    assignment_github_repository = GitHubRepository.new(organization.github_client, assignment_repo.github_repo_id)

    assignment_github_repository.full_name
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
