# frozen_string_literal: true

class Roster < ApplicationRecord
  has_many :roster_entries
  has_many :organizations
end
