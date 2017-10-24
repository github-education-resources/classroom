# frozen_string_literal: true

class Organization < ApplicationRecord
  include Flippable
  include Sluggable

  update_index("stafftools#organization") { self }

  default_scope { where(deleted_at: nil) }

  has_many :assignments,              dependent: :destroy
  has_many :groupings,                dependent: :destroy
  has_many :group_assignments,        dependent: :destroy
  has_many :repo_accesses,            dependent: :destroy

  belongs_to :roster, optional: true

  has_many :organization_users
  has_many :users, through: :organization_users

  validates :github_id, presence: true, uniqueness: true

  validates :title, presence: true
  validates :title, length: { maximum: 60 }

  validates :slug, uniqueness: true

  validates :webhook_id, uniqueness: true, allow_nil: true

  before_destroy :silently_remove_organization_webhook

  def all_assignments(with_groupings: false, with_invitations: false)
    assignment_includes = []
    assignment_includes << :assignment_invitation if with_invitations

    group_assignment_includes = []
    group_assignment_includes << :group_assignment_invitation if with_invitations
    group_assignment_includes << :grouping                    if with_groupings

    assignments.includes(*assignment_includes) + group_assignments.includes(*group_assignment_includes)
  end

  def github_client
    token = users.limit(1).order("RANDOM()").pluck(:token)[0]
    Octokit::Client.new(access_token: token)
  end

  def github_organization
    @github_organization ||= GitHubOrganization.new(github_client, github_id)
  end

  def slugify
    self.slug = "#{github_id} #{title}".parameterize
  end

  def silently_remove_organization_webhook
    begin
      github_organization.remove_organization_webhook(webhook_id)
    rescue GitHub::Error => err
      logger.info err.message
    end

    true
  end
end
