# frozen_string_literal: true

class Roster < ApplicationRecord
  has_many :roster_entries
  has_many :organizations

  validates :identifier_name, presence: true
  validates :roster_entries, presence: true

  def unlinked_entries
    roster_entries.select do |entry|
      entry.user.nil?
    end
  end
end
