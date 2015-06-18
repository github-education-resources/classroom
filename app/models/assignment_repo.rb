class AssignmentRepo < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :repo_access

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true
end
