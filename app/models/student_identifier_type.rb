# frozen_string_literal: true
class StudentIdentifierType < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  has_many :student_identifiers

  belongs_to :organization, -> { unscope(where: :deleted_at) }
  validates :organization, presence: true

  validates :name, presence: true, uniqueness: { scope: :organization }
end
