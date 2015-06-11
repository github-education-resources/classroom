class IndividualAssignment < ActiveRecord::Base
  has_one :individual_assignment_invitation, dependent: :destroy

  has_many :individual_assignment_repos

  belongs_to :organization

  validates :title, presence: true
end
