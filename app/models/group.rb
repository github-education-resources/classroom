class Group < ActiveRecord::Base
  belongs_to :grouping

  has_and_belongs_to_many :repo_accesses

  validates :github_team_id, presence: true
  validates :github_team_id, uniqueness: true

  validates :grouping, presence: true

  validates :title, presence: true
end
