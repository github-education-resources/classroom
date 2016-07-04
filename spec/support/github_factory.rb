# frozen_string_literal: true
require_relative 'vcr'

module GitHubFactory
  def self.create_classroom_student
    User.create(uid: classroom_student_github_id, token: classroom_student_github_token)
  end

  def self.create_owner_classroom_org
    owner = User.create(uid: classroom_owner_github_id, token: classroom_owner_github_token)
    Organization.create(title:     classroom_owner_organization_github_login,
                        github_id: classroom_owner_organization_github_id,
                        users:     [owner])
  end
end
