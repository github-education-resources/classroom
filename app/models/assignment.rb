class Assignment < ActiveRecord::Base
  has_one :assignment_invitation, dependent: :destroy

  has_many :assignment_repos

  belongs_to :organization

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }

  validate :uniqueness_of_title_across_organization

  def assignment_invitation
    super || NullAssignmentInvitation.new
  end

  def public?
    public_repo
  end

  def private?
    !public_repo
  end

  private

  def uniqueness_of_title_across_organization
    return unless GroupAssignment.where(title: title, organization: organization).present?
    errors.add(:title, 'has already been taken')
  end
end
