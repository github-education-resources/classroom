class GroupAssignmentRepo < ActiveRecord::Base
  has_one :group

  validates :github_repo_id, presence: true
end
