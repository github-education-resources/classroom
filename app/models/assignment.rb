class Assignment < ActiveRecord::Base
  has_many   :assignment_repos
  has_one    :assignment_invitation, dependent: :destroy

  belongs_to :organization

  validates_presence_of :title

  def assignment_invitation
    super || NullAssignmentInvitation.new
  end
end
