class GroupAssignmentInvitation < ActiveRecord::Base
  has_one :grouping,     through: :group_assignment
  has_one :organization, through: :group_assignment

  has_many :groups, through: :grouping

  belongs_to :group_assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeemed?(invitee, group_options)
    invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, invitee, group_options)
    invitation_redeemer.redeemed?
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
