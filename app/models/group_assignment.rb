# frozen_string_literal: true

class GroupAssignment < ApplicationRecord
  include Flippable
  include GitHubPlan
  include ValidatesNotReservedWord

  update_index("stafftools#group_assignment") { self }

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

  alias_attribute :invitation, :group_assignment_invitation
  alias_attribute :repos, :group_assignment_repos

  def private?
    !public_repo
  end

  def public?
    public_repo
  end

  def starter_code?
    starter_code_repo_id.present?
  end

  def starter_code_repository
    return unless starter_code?
    @starter_code_repository ||= GitHubRepository.new(creator.github_client, starter_code_repo_id)
  end

  def to_param
    slug
  end

  private

  def uniqueness_of_slug_across_organization
    return if Assignment.where(slug: slug, organization: organization).blank?
    errors.add(:slug, :taken)
  end
end
