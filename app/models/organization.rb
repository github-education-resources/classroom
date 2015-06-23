class Organization < ActiveRecord::Base
  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, :title, presence:   true
  validates :github_id,         uniqueness: true

  def all_assignments
    (assignments + group_assignments) || NullAssignment.new
  end

  def github_login
    owner.github_client.organization(github_id).login
  end

  def owner
    users.sample
  end
end
