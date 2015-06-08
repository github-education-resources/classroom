class IndividualAssignmentRepo < ActiveRecord::Base
  has_one    :repo_access
  belongs_to :individual_assignment

  validates_presence_of :github_repo_id
end
