class Organization < ActiveRecord::Base
  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, :title, presence:   true
  validates :github_id,         uniqueness: true

  def all_assignments
    (self.assignments + self.group_assignments) || NullAssignment.new
  end
end
