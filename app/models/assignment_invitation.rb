class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates_presence_of   :key
  validates_uniqueness_of :key

  after_initialize :assign_key

  def redeem(user)
    repo_access = user.repo_accesses.find_or_create_by(organization: organization)

    if repo_access.new_record?
      repo_access.create_github_team(assignment_owner, "Team: #{organization.repo_accesses.count + 1}")
      repo_access.save!
    end

    assignment_repo = self.assignment.assignment_repos.find_or_create_by(repo_access: repo_access)

    if assignment_repo.new_record?
      assignment_repo.repo_access = repo_access

      new_repo_name = "#{assignment.title} #{assignment.assignment_repo.count + 1}"
      assignment_repo.create_github_repo(assignment_owner, organization, new_repo_name)

      assignment_repo.save!
    end

    assignment_owner.github_client.repository(assignment_repo.github_repo_id)
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  def assignment_owner
    organization.users.find do |user|
      user.github_client.organization_admin?(organization.github_id)
    end
  end

  def organization
    self.assignment.organization
  end
end
