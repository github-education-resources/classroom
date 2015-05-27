class Invitation < ActiveRecord::Base
  belongs_to :organization

  validates_presence_of   :key, :team_id, :title, :organization_id
  validates_uniqueness_of :key, :team_id

  after_initialize :assign_key

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
