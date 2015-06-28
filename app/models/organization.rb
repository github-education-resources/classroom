class Organization < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, presence: true, uniqueness: true
  validates :title,     presence: true, uniqueness: { case_sensitive: false }

  # Public: Retrieve both Assignments and Group Assignments
  # for the organization.
  #
  # Returns an array of assignments and group assignments
  # if the organization doesn't have any yet
  def all_assignments
    assignments + group_assignments
  end

  # Public: Retrieve a properly authenticated GitHubClient
  # on for the organization
  #
  def github_client
    users.sample.github_client
  end
end
