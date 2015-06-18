class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeemed?(invitee)
    invitation_redeemer = AssignmentInvitationRedeemer.new(invitee)
    binding.pry
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
