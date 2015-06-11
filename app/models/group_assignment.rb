class GroupAssignment < ActiveRecord::Base
  has_one :grouping
  has_one :group_assignment_invitation, dependent: :destroy

  has_many :group_assignment_repos

  belongs_to :organization
end
