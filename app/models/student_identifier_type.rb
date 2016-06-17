# frozen_string_literal: true
class StudentIdentifierType < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  belongs_to :organization, -> { unscope(where: :deleted_at) }
  has_many :student_identifiers

  enum content_type: [:text, :number, :email]

  validates :organization, presence: true
end
