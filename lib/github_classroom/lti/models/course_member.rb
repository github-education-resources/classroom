class GitHubClassroom::LTI::Models::CourseMember
  attr_reader :user_id, :name, :email, :role
  def initialize(user_id: nil, name: nil, email: nil, role: [])
    @user_id = user_id
    @name = name
    @email = email
    @role = role
  end

  def self.from_membership_service membership
    member = membership.member
    self.new(
      user_id: member.user_id,
      email: member.email,
      name: member.name,
      role: membership.role
    )
  end
end
