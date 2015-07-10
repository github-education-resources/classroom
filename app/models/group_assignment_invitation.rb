class GroupAssignmentInvitation < ActiveRecord::Base
  has_one :grouping,     through: :group_assignment
  has_one :organization, through: :group_assignment

  has_many :groups, through: :grouping

  belongs_to :group_assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem(invitee, group = nil, group_title = nil)
    invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, group, group_title)
    invitation_redeemer.redeem_for(invitee)
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
