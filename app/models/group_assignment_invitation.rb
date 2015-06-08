class GroupAssignmentInvitation < ActiveRecord::Base
  belongs_to :group_assignment
  belongs_to :organization

  validates_presence_of   :key
  validates_uniqueness_of :key

  after_initialize :assign_key

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
