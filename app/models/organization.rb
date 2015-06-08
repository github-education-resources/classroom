class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users

  has_many :individual_assignments, dependent: :destroy
  has_many :group_assignments,      dependent: :destroy
  has_many :groupings,              dependent: :destroy
  has_one  :invitation,             dependent: :destroy
  has_many :repo_accesses,          dependent: :destroy

  validates_presence_of   :github_id, :title
  validates_uniqueness_of :github_id

  def invitation
    super || NullInvitation.new
  end
end
