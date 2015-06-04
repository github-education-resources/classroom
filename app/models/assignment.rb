class Assignment < ActiveRecord::Base
  has_one    :invitation
  belongs_to :organization

  validates_presence_of :title
end
