# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
class GitHubClassroom::LTI::Models::CourseMember
  attr_reader :user_id, :name, :email, :role

  def initialize(user_id: nil, name: nil, email: nil, role: [])
    @user_id = user_id
    @name = name
    @email = email
    @role = role
  end
end
# rubocop:enable ClassAndModuleChildren
