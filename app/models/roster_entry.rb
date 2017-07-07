# frozen_string_literal: true

class RosterEntry < ApplicationRecord
  belongs_to :roster
  belongs_to :user, optional: true

  validates :identifier, presence: true
  validates :roster,     presence: true
end
