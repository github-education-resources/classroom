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

  # Public
  #
  def all_assignments
    assignments + group_assignments
  end

  # Public
  #
  def github_client
    users.sample.github_client
  end

  private

  def slug_candidate
    "#{github_id}-#{title}"
  end
end
