class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem(invitee)
    invitation_redeemer = AssignmentInvitationRedeemer.new(assignment, invitee)
    invitation_redeemer.redeem
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
