class NullInvitation
  attr_accessor :id, :key, :team_id, :title, :organization_id, :user_id

  def user
    User.none
  end

  def organization
    Organization.none
  end

  def to_param
    @key
  end

  def to_partial_path
    'invitations/null'
  end
end
