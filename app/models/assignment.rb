class Assignment < ActiveRecord::Base
  include GitHubPlan

  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_one :assignment_invitation, dependent: :destroy

  has_many :assignment_repos, dependent: :destroy
  has_many :repo_accesses,    through:   :assignment_repos
  has_many :users,            through:   :repo_accesses

  belongs_to :creator, class_name: User
  belongs_to :organization

  validates :creator, presence: true

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }

  validate :uniqueness_of_title_across_organization

  def assignment_invitation
    super || NullAssignmentInvitation.new
  end

  alias_method :invitation, :assignment_invitation

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

  def uniqueness_of_title_across_organization
    return unless GroupAssignment.where(title: title, organization: organization).present?
    errors.add(:title, 'has already been taken')
  end
end
