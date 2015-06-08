class Grouping < ActiveRecord::Base
  has_many   :groups
  belongs_to :organization

  validates_presence_of :title
end
