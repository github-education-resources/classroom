class GroupAssignment < ActiveRecord::Base
  has_one :group_assignment_invitation, dependent: :destroy

  has_many :group_assignment_repos

  belongs_to :grouping
  belongs_to :organization
end
