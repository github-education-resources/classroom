# frozen_string_literal: true
class StudentIdentifier < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  belongs_to :type,
             class_name: 'StudentIdentifierType',
             foreign_key: 'student_identifier_type_id'

  belongs_to :organization, -> { unscope(where: :deleted_at) }
  belongs_to :user

  validates :type,         presence: true, uniqueness: { scope: [:user, :organization] }
  validates :user,         presence: true, uniqueness: { scope: [:organization, :type] }
  validates :organization, presence: true, uniqueness: { scope: [:user, :type] }

  validates :value, presence: true, uniqueness: { scope: [:organization, :type] }
end
