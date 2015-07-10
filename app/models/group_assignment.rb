class GroupAssignment < ActiveRecord::Base
  has_one :group_assignment_invitation, dependent: :destroy

  has_many :group_assignment_repos, dependent: :destroy

  belongs_to :grouping
  belongs_to :organization

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }

  validate :uniqueness_of_title_across_organization

  def group_assignment_invitation
    super || NullGroupAssignmentInvitation.new
  end

  def public?
    public_repo
  end

  def private?
    !public_repo
  end

  private

  def uniqueness_of_title_across_organization
    return unless Assignment.where(title: title, organization: organization).present?
    errors.add(:title, 'has already been taken')
  end
end
