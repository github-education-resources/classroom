class IndividualAssignment < ActiveRecord::Base
  has_many   :individual_assignment_repos
  belongs_to :organiation

  validates_presence_of :title
end
