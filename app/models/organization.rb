class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates_presence_of   :title, :github_id
  validates_uniqueness_of :title, :github_id
end
