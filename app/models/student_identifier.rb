# frozen_string_literal: true
class StudentIdentifier < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization, -> { unscope(where: :deleted_at) }

  belongs_to :student_identifier_type

  validates :organization, presence: true
  validates :organization, uniqueness: { scope: :user }

  validates :user, presence: true
  validates :user, uniqueness: { scope: :organization }
end
