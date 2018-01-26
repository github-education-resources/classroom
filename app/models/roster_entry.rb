# frozen_string_literal: true

class RosterEntry < ApplicationRecord
  belongs_to :roster
  belongs_to :user, optional: true

  validates :identifier, presence: true
  validates :roster,     presence: true

  def self.to_csv
    header = %i[identifier github_username name]
    roster_array = []

    CSV.generate(headers: true, col_sep: ",", force_quotes: true) do |csv|
      csv << header

      all.sort_by(&:identifier).each do |entry|
        row   = []
        login = ""
        name  = ""
        if entry.user
          login = entry.user.github_user.login
          name  = entry.user.github_user.name ? entry.user.github_user.name : ""
        end

        row << entry.identifier
        row << login
        row << name

        roster_array << row
      end
      roster_array.each do |r|
        csv << r
      end
    end
  end
end
