class GroupAssignment < ActiveRecord::Base
  has_one :group_assignment_invitation, dependent: :destroy

  has_many :groups,                 through: :grouping
  has_many :group_assignment_repos, dependent: :destroy

  belongs_to :grouping
  belongs_to :organization

  def public?
    public_repo
  end

  def private?
    !public_repo
  end
end
