class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem_for(invitee)
    invitation_redeemer = AssignmentInvitationRedeemer.new(assignment)
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
