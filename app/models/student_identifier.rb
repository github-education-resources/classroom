# frozen_string_literal: true
class StudentIdentifier < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :user
  belongs_to :organization, -> { unscope(where: :deleted_at) }

  belongs_to :student_identifier_type

  validates :organization, presence: true
  validates :organization, uniqueness: { scope: [:user, :student_identifier_type] }

  validates :user, presence: true
  validates :user, uniqueness: { scope: [:organization, :student_identifier_type] }

  validates :student_identifier_type, presence: true
  validates :student_identifier_type, uniqueness: { scope: [:user, :organization] }

  validates :value, presence: true
end
