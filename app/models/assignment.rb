# frozen_string_literal: true

class Assignment < ApplicationRecord
  include Flippable
  include GitHubPlan
  include StarterCodeImportable
  include ValidatesNotReservedWord
  include StafftoolsSearchable

  define_pg_search(columns: %i[id title slug])

  default_scope { where(deleted_at: nil) }

  has_one :assignment_invitation, dependent: :destroy, autosave: true
  has_one :deadline, dependent: :destroy, as: :assignment

  has_many :assignment_repos, dependent: :destroy
  has_many :users,            through:   :assignment_repos

  belongs_to :creator, class_name: "User"
  belongs_to :organization

  validates :creator, presence: true

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

  validates :assignment_invitation, presence: true

  validate :uniqueness_of_slug_across_organization
  validate :starter_code_repository_not_empty

  validate :starter_code_repository_is_template

  alias_attribute :invitation, :assignment_invitation
  alias_attribute :repos, :assignment_repos
  alias_attribute :template_repos_enabled?, :template_repos_enabled

  def private?
    !public_repo
  end

  def public?
    public_repo
  end

  def to_param
    slug
  end

  private

  def uniqueness_of_slug_across_organization
    return if GroupAssignment.where(slug: slug, organization: organization).blank?
    errors.add(:slug, :taken)
  end

  def starter_code_repository_not_empty
    return unless starter_code? && starter_code_repository.empty?
    errors.add :starter_code_repository, "cannot be empty. Select a repository that is not empty or create the"\
      " assignment without starter code."
  end
end
