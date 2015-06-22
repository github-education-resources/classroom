class Grouping < ActiveRecord::Base
  has_many :groups, dependent: :destroy

  belongs_to :organization

  validates :title, presence: true
end
