class Grouping < ActiveRecord::Base
  has_many :groups

  belongs_to :organization

  validates :title, presence: true
end
