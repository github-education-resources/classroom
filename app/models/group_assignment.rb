class GroupAssignment < ActiveRecord::Base
  has_one  :grouping
  has_many :group_assignment_repos
  has_one  :group_assignment_invitation
end
