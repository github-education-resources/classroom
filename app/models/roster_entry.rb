# frozen_string_literal: true

class RosterEntry < ApplicationRecord
  belongs_to :roster
  belongs_to :user, optional: true

  validates :identifier, presence: true
  validates :roster,     presence: true

  def self.to_csv
    CSV.generate(headers: true, col_sep: ",", force_quotes: true) do |csv|
      csv << %i[identifier github_username name]

      all.sort_by(&:identifier).each do |entry|
        github_user = entry.user.try(:github_user)
        login = github_user.try(:login) || ""
        name = github_user.try(:name) || ""
        csv << [entry.identifier, login, name]
      end
    end
  end
end
