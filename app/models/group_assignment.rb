class GroupAssignment < ActiveRecord::Base
  include GitHubPlan

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_one :group_assignment_invitation, dependent: :destroy, autosave: true

  has_many :group_assignment_repos, dependent: :destroy

  belongs_to :creator, class_name: User
  belongs_to :grouping
  belongs_to :organization

  validates :creator, presence: true

  validates :grouping, presence: true

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }
  validates :title, length: { maximum: 60 }

  validate :uniqueness_of_title_across_organization

  alias_attribute :invitation, :group_assignment_invitation

  def private?
    !public_repo
  end

  def public?
    public_repo
  end

  def starter_code?
    starter_code_repo_id.present?
  end

  private

  def organization_slug
    organization.slug
  end

  def should_generate_new_friendly_id?
    title_changed?
  end

  def slug_candidates
    [
      [:title],
      [:title, :organization_slug]
    ]
  end

  def uniqueness_of_title_across_organization
    return unless Assignment.where(slug: normalize_friendly_id(title), organization: organization).present?
    errors.add(:title, 'title is already in use for your organization')
  end
end
