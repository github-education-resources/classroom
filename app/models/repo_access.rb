class RepoAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :github_team_id, presence: true
end
