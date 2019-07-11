# frozen_string_literal: true

class Grouping < ApplicationRecord
  include Sluggable
  include PgSearch

  pg_search_scope(
    :search,
    against: %i[
      id
      title
      slug
    ],
    using: {
      tsearch: {
        dictionary: "english"
      }
    }
  )

  has_many :groups, dependent: :destroy
  has_many :users, through: :groups, source: :repo_accesses

  belongs_to :organization

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }

  validates :slug, uniqueness: { scope: :organization }
end
