class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_one :invitation, dependent: :destroy

  validates_presence_of   :title, :github_id

  validates_uniqueness_of :github_id,        message:   'organization is already in use'
  validates_uniqueness_of :students_team_id, allow_nil: true
  validates_uniqueness_of :title
end
