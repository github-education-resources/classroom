class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_one :invitation

  validates_presence_of   :title, :github_id
  validates_uniqueness_of :title, :students_team_id
  validates_uniqueness_of :github_id, message: 'organization is already in use'
end
