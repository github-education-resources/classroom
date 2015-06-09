class AssignmentRepo < ActiveRecord::Base
  has_one    :repo_access
  belongs_to :assignment

  validates_presence_of :github_repo_id
end
