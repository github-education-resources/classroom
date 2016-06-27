# frozen_string_literal: true
class StudentIdentifierType < ActiveRecord::Base
  belongs_to :organization, -> { unscope(where: :deleted_at) }
  has_many :student_identifiers

  enum content_type: [:text, :number, :email]

  validates :organization, presence: true
end
