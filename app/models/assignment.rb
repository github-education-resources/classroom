class Assignment < ActiveRecord::Base
  has_one :assignment_invitation, dependent: :destroy

  has_many :assignment_repos

  belongs_to :organization

  validates :title, presence: true

  def assignment_invitation
    super || NullAssignmentInvitation.new
  end
end
