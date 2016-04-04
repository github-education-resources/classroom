class Organization < ActiveRecord::Base
  include Flippable
  include Sluggable

  update_index('stafftools#organization') { self }

  default_scope { where(deleted_at: nil) }

  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, presence: true, uniqueness: true

  validates :title, presence: true
  validates :title, length: { maximum: 60 }

  validates :slug, uniqueness: true

  def access_token
    users.limit(1).order('RANDOM()').pluck(:access_token)[0]
  end

  def all_assignments
    assignments + group_assignments
  end

  def geo_pattern_data_uri
    @geo_pattern_data_uri ||= GeoPattern.generate(github_id, color: '#5fb27b').to_data_uri
  end

  def github_organization
    @github_organization ||= GitHubOrganization.new(id: github_id, access_token: access_token)
  end

  def slugify
    self.slug = "#{github_id} #{title}".parameterize
  end
end
