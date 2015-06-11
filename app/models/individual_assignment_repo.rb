class IndividualAssignmentRepo < ActiveRecord::Base
  has_one :repo_access

  belongs_to :individual_assignment

  validate :github_repo_id, presence: true
end
