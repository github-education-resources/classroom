class GroupAssignment < ActiveRecord::Base
  include GitHubPlan

  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

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

  validate :uniqueness_of_title_across_organization

  alias_attribute :invitation, :group_assignment_invitation

  # Public: Determine if the GroupAssignment is private
  #
  # Example
  #
  #  group_assignment.public?
  #  # => true
  #
  # Returns a boolean
  def private?
    !public_repo
  end

  # Public: Determine if the GroupAssignment is public
  #
  # Example
  #
  #  group_assignment.private?
  #  # => true
  #
  # Returns a boolean
  def public?
    public_repo
  end

  # Public: Determine if the GroupAssignment has starter code
  #
  # Example
  #
  #  group_assignment.starter_code?
  #  # => true
  #
  # Returns if the starter_code_repo_id column is not NULL
  def starter_code?
    starter_code_repo_id.present?
  end

  private

  # Internal: Verify that there aren't any Assignments in the
  # Assignments Organization that have the same title.
  #
  # This will add an error to the title column if there is a match
  def uniqueness_of_title_across_organization
    return unless Assignment.where(title: title, organization: organization).present?
    errors.add(:title, 'title is already in use for your organization')
  end
end
