# frozen_string_literal: true

class GroupAssignment < ApplicationRecord
  include Flippable
  include GitHubPlan
  include StarterCodeImportable
  include ValidatesNotReservedWord
  include StafftoolsSearchable

  define_pg_search(columns: %i[id title slug])

  default_scope { where(deleted_at: nil) }

  has_one :group_assignment_invitation, dependent: :destroy, autosave: true
  has_one :deadline, dependent: :destroy, as: :assignment

  has_many :group_assignment_repos, dependent: :destroy

  belongs_to :creator, class_name: "User"
  belongs_to :grouping
  belongs_to :organization

  validates :creator, presence: true

  validates :grouping, presence: true

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, length: { maximum: 60 }
  validates :title, uniqueness: { scope: :organization_id }
  validates_not_reserved_word :title

  validates :slug, uniqueness: { scope: :organization_id }
  validates :slug, presence: true
  validates :slug, length: { maximum: 60 }
  validates :slug, format: { with: /\A[-a-zA-Z0-9_]*\z/,
                             message: "should only contain letters, numbers, dashes and underscores" }

  validate :uniqueness_of_slug_across_organization
  validate :organization_is_not_archived
  validate :max_teams_less_than_group_count
  validate :starter_code_repository_not_empty, if: :will_save_change_to_starter_code_repo_id?
  validate :starter_code_repository_is_template,
    if: -> { :will_save_change_to_starter_code_repo_id? || :will_save_change_to_template_repos_enabled }

  validates_associated :grouping

  alias_attribute :invitation, :group_assignment_invitation
  alias_attribute :repos, :group_assignment_repos
  alias_attribute :template_repos_enabled?, :template_repos_enabled

  after_create :track_private_repo_belonging_to_user

  def private?
    !public_repo
  end

  def public?
    public_repo
  end

  def visibility=(visibility)
    self.public_repo = visibility != "private"
  end

  def to_param
    slug
  end

  private

  def uniqueness_of_slug_across_organization
    return if Assignment.where(slug: slug, organization: organization).blank?
    errors.add(:slug, :taken)
  end

  def max_teams_less_than_group_count
    return unless max_teams.present? && grouping.present? && max_teams < group_count = grouping.groups.count
    if new_record?
      errors.add(:max_teams, "is less than the number of teams in the existing set you've selected (#{group_count})")
    else
      errors.add(:max_teams, "is less than the number of existing teams (#{group_count})")
    end
  end

  def organization_is_not_archived
    errors.add(:base, "You cannot create or modify group assignments in archived classrooms") if organization.archived?
  end
end
