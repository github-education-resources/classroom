class Organization < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidate, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, presence: true, uniqueness: true
  validates :title,     presence: true
  validates :title,     length: { maximum: 60 }

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
  # Example
  #
  #   organization.github_client
  #   # => #<Octokit::Client:0x3fe32a050c4c>
  #
  # Returns an authenticated Octokit::Client
  def github_client
    users.sample.github_client
  end

  private

  def slug_candidate
    "#{github_id}-#{title}"
  end
end
