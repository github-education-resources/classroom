class Invitation < ActiveRecord::Base
  extend FriendlyId
  friendly_id :key

  belongs_to :organization

  validates_presence_of   :key, :team_id, :title
  validates_uniqueness_of :key, :team_id

  after_initialize :assign_key

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
