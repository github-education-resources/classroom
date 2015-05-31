class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_one :invitation, dependent: :destroy

  validates_presence_of   :github_id
  validates_uniqueness_of :github_id, message: 'organization is already in use'

  validates_presence_of   :title
end
