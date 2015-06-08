class GroupAssignmentRepo < ActiveRecord::Base
  has_one :group

  validates_presence_of :github_repo_id
end
