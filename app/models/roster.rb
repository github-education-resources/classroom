# frozen_string_literal: true

class Roster < ApplicationRecord
  has_many :roster_entries, dependent: :destroy
  has_many :organizations

  validates :identifier_name, presence: true
  validates :roster_entries, presence: true

  include DuplicateRosterEntries

  def unlinked_entries
    roster_entries.includes(:user).select do |entry|
      entry.user.nil?
    end
  end
end
