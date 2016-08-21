# frozen_string_literal: true
class StudentIdentifier < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :user
  belongs_to :classroom, -> { unscope(where: :deleted_at) }

  belongs_to :student_identifier_type

  validates :classroom, presence: true
  validates :classroom, uniqueness: { scope: [:user, :student_identifier_type] }

  validates :user, presence: true
  validates :user, uniqueness: { scope: [:classroom, :student_identifier_type] }

  validates :student_identifier_type, presence: true
  validates :student_identifier_type, uniqueness: { scope: [:user, :classroom] }
end
