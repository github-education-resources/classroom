class GroupAssignmentRepo < ActiveRecord::Base
  belongs_to :group_assignment
  belongs_to :group

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true
end
