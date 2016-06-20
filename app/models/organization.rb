# frozen_string_literal: true
class Organization < ActiveRecord::Base
  include Flippable
  include Sluggable

  update_index('stafftools#organization') { self }

  default_scope { where(deleted_at: nil) }

  has_many :assignments,              dependent: :destroy
  has_many :groupings,                dependent: :destroy
  has_many :group_assignments,        dependent: :destroy
  has_many :repo_accesses,            dependent: :destroy
  has_many :student_identifier_types, dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, presence: true, uniqueness: true

  validates :title, presence: true
  validates :title, length: { maximum: 60 }

  validates :slug, uniqueness: true

  validates :webhook_id, uniqueness: true, allow_nil: true

  def all_assignments(with_invitations: false)
    return assignments + group_assignments unless with_invitations

    assignments.includes(:assignment_invitation) + \
      group_assignments.includes(:group_assignment_invitation)
  end

  def github_client
    token = users.limit(1).order('RANDOM()').pluck(:token)[0]
    Octokit::Client.new(access_token: token)
  end

  def github_organization
    @github_organization ||= GitHubOrganization.new(github_client, github_id)
  end

  def slugify
    self.slug = "#{github_id} #{title}".parameterize
  end
end
