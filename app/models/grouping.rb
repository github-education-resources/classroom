class Grouping < ActiveRecord::Base
  belongs_to :organization

  has_many :groups

  validates :title, presence: true
end
