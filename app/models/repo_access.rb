class RepoAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates_presence_of :github_team_id
end
