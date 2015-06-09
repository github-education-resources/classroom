class AssignmentInvitation < ActiveRecord::Base
  belongs_to :assignment

  validates_presence_of   :key
  validates_uniqueness_of :key

  after_initialize :assign_key

  def redeem(other_user)

  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
