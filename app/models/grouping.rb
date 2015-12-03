class Grouping < ActiveRecord::Base

  update_index('stafftools#grouping') { self }

  has_many :groups, dependent: :destroy
  has_many :users, through: :groups, source: :repo_accesses

  belongs_to :organization

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }
end
