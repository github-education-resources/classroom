class Invitation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user

  validates_presence_of   :key, :team_id, :title, :organization_id, :user_id
  validates_uniqueness_of :key, :team_id

  after_initialize :assign_key

  def accept_invitation(other_user)
    user.github_client.add_team_membership(team_id, other_user.login)
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
