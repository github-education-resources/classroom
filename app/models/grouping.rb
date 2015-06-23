class Grouping < ActiveRecord::Base
  has_many :groups, dependent: :destroy
  has_many :users, through: :groups, source: :repo_accesses

  belongs_to :organization

  validates :title, presence: true
end
