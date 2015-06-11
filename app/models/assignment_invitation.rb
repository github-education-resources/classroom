class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem(user)
    repo_access     = find_or_create_repo_access_by_organization(user, assignment.organization)
    assignment_repo = find_or_create_assignment_repo_by_repo_access(repo_access)

    assignment_owner.github_client.repository?(assignment_repo.github_repo_id)
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  def assignment_owner
    assignment.organization.users.find do |user|
      user.github_client.organization_admin?(assignment.organization.github_id)
    end
  end

  def find_or_create_assignment_repo_by_repo_access(repo_access)
    assignment_repo = assignment.assignment_repos.find_or_create_by(repo_access: repo_access)

    if assignment_repo.new_record?
      assignment_repo.repo_access = repo_access

      new_repo_name = "#{assignment.title} #{Time.zone.now}"
      assignment_repo.create_github_repo(assignment_owner, assignment.organization, new_repo_name)

      assignment_repo.save!
    end

    assignment_repo
  end

  def find_or_create_repo_access_by_organization(user, organization)
    repo_access = user.repo_accesses.find_or_create_by(organization: organization)

    if repo_access.new_record?
      repo_access.create_github_team(assignment_owner, "Team: #{Time.zone.now}")
      repo_access.save!
    end

    repo_access
  end
end
