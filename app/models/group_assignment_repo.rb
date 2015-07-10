class GroupAssignmentRepo < ActiveRecord::Base
  has_many :repo_accesses, through: :group

  belongs_to :group_assignment
  belongs_to :group

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :group_assignment, presence: true

  validates :group, presence: true
  validates :group, uniqueness: { scope: :group_assignment }
end
