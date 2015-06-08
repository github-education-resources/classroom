class IndividualAssignment < ActiveRecord::Base
  has_many   :individual_assignment_repos
  has_one    :individual_assignment_invitation, dependent: :destroy
  belongs_to :organization

  validates_presence_of :title
end
