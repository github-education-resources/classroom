require_relative 'vcr'

module GitHubFactory
  def self.create_classroom_student
    User.create(uid: 12_435_329, token: classroom_student_github_token)
  end

  def self.create_owner_classroom_org
    owner = User.create(uid: 564_113, token: classroom_owner_github_token)
    Organization.create(title: 'cse3901-osu-2015su', github_id: 8_795_167, users: [owner])
  end
end
