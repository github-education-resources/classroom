class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates_presence_of   :login, :github_id
  validates_uniqueness_of :login, :github_id
end
