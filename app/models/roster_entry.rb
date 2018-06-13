# frozen_string_literal: true

class RosterEntry < ApplicationRecord
  class IdentifierCreationError < StandardError; end
  belongs_to :roster
  belongs_to :user, optional: true

  validates :identifier, presence: true
  validates :roster,     presence: true

  before_create :validate_identifiers_are_unique_to_roster

  def self.to_csv
    CSV.generate(headers: true, col_sep: ",", force_quotes: true) do |csv|
      csv << %i[identifier github_username github_id name]

      all.sort_by(&:identifier).each do |entry|
        github_user = entry.user.try(:github_user)
        github_id = github_user.try(:id) || ""
        login = github_user.try(:login) || ""
        name = github_user.try(:name) || ""
        csv << [entry.identifier, login, github_id, name]
      end
    end
  end

  # Orders the relation for display in a view.
  # Ordering is:
  # first:  Accepted the assignment
  # second: Linked but not accepted
  # last:   Unlinked student
  #
  # with a secondary sort on ID to ensure ties are always handled in the same way
  def self.order_for_view(assignment)
    users_with_repo = assignment.repos.pluck(:user_id)
    sql_formatted_users = users_with_repo.empty? ? "(NULL)" : "(#{users_with_repo.join(',')})"

    order <<~SQL
      CASE
        WHEN roster_entries.user_id IS NULL THEN 2                   /* Not linked */
        WHEN roster_entries.user_id IN #{sql_formatted_users} THEN 0 /* Accepted */
        ELSE 1                                                       /* Linked but not accepted */
      END
      , id
    SQL
  end

  # Restrict relation to only entries that have not joined a team
  def self.students_not_on_team(group_assignment)
    students_on_team = group_assignment.repos.map(&:repo_accesses).flatten.map(&:user).map(&:id).uniq
    sql_formatted_students_on_team = students_on_team.empty? ? "(NULL)" : "(#{students_on_team.join(',')})"

    where <<~SQL
      roster_entries.user_id IS NULL OR
      roster_entries.user_id NOT IN #{sql_formatted_students_on_team}
    SQL
  end

  # Takes an array of identifiers and creates a
  # roster entry for each. Omits duplicates, and
  # raises IdentifierCreationError if there is an
  # error.
  #
  # Returns the created entries.

  # rubocop:disable Metrics/MethodLength
  def self.create_entries(identifiers:, roster:)
    created_entries = []
    RosterEntry.transaction do
      identifiers.each do |identifier|
        roster_entry = RosterEntry.create(identifier: identifier, roster: roster)

        if !roster_entry.persisted?
          raise IdentifierCreationError unless roster_entry.errors.include?(:identifier)
        else
          created_entries << roster_entry
        end
      end
    end

    created_entries
  end
  # rubocop:enable Metrics/MethodLength

  private

  def validate_identifiers_are_unique_to_roster
    return unless RosterEntry.find_by(roster: roster, identifier: identifier)

    errors[:identifier] << "Identifier must be unique in the roster."
    throw(:abort)
  end
end
