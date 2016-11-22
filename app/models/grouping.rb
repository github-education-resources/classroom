# frozen_string_literal: true
class Grouping < ApplicationRecord
  include Sluggable

  update_index('stafftools#grouping') { self }

  has_many :groups, dependent: :destroy
  has_many :users, through: :groups, source: :repo_accesses

  belongs_to :classroom

  validates :classroom, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :classroom }

  validates :slug, uniqueness: { scope: :classroom }
end
