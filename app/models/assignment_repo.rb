class AssignmentRepo < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :repo_access

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :repo_access, presence:   true
  validates :repo_access, uniqueness: { scope: :assignment }
end
