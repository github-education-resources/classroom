require_relative 'vcr'

module GitHubFactory
  def self.create_classroom_student
    User.create(uid: classroom_student_id, token: classroom_student_github_token)
  end

  def self.create_owner_classroom_org
    owner = User.create(uid: classroom_owner_id, token: classroom_owner_github_token)
    Organization.create(title: classroom_owner_github_org, github_id: classroom_owner_github_org_id, users: [owner])
  end
end
