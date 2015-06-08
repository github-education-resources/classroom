class IndividualAssignment < ActiveRecord::Base
  has_many   :individual_assignment_repos
  has_one    :individual_assignment_invitation
  belongs_to :organiation

  validates_presence_of :title
end
