# frozen_string_literal: true

class RosterEntry < ApplicationRecord
  belongs_to :roster
  belongs_to :user, optional: true

  validates :identifier, presence: true
  validates :roster,     presence: true

  # Orders the relation for display in a view.
  # Ordering is:
  # first:  roster entry has no user
  # second: roster entry has a user who's created a repo before
  # last:   everything else
  #
  # with a secondary sort on ID to ensure ties are always handled in the same way
  def self.order_for_view(assignment)
      users_with_repo = assignment.repos.pluck(:user_id)
      sql_formatted_users = "(#{users_with_repo.join(',')})"

      order <<~SQL
        CASE
          WHEN roster_entries.user_id IS NULL THEN 2
          WHEN roster_entries.user_id IN #{sql_formatted_users} THEN 1
          ELSE 0
        END
        , id
      SQL
  end
end
