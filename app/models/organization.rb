class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_one  :invitation,  dependent: :destroy
  has_many :assignments, dependent: :destroy

  validates_presence_of   :github_id, :title
  validates_uniqueness_of :github_id, message: 'organization is already in use'
  validates_uniqueness_of :students_team_id

  def invitation
    super || NullInvitation.new
  end
end
