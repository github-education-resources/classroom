class GroupAssignmentInvitation < ActiveRecord::Base
  belongs_to :group_assignment

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
