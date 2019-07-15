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
  validate :max_teams_less_than_group_count
  validate :starter_code_repository_not_empty
  validate :starter_code_repository_is_a_template_repository  

  alias_attribute :invitation, :group_assignment_invitation
  alias_attribute :repos, :group_assignment_repos
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

  def starter_code_repository_not_empty
    return unless starter_code? && starter_code_repository.empty?
    errors.add :starter_code_repository, "cannot be empty. Select a repository that is not empty or create the"\
      " assignment without starter code."
  end

  def starter_code_repository_is_a_template_repository
    return unless use_template_repos?

    options = { accept: "application/vnd.github.baptiste-preview" }
    endpoint_url = "https://api.github.com/repositories/#{starter_code_repo_id}"
    starter_code_github_repository = creator.github_client.get(endpoint_url, options)

    return if starter_code_github_repository.is_template
    errors.add(
      :starter_code_repository,
      "is not a template repository. Make it a template repository to use template cloning."
    )
  end
end
