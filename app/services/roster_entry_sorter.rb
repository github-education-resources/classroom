# frozen_string_literal: true

# Sorts roster entries by:
# - Linked + accepted
# - Linked + not accepted
# - Not linked

class RosterEntrySorter
  attr_reader :entries, :assignment

  def initialize(roster_entries, assignment)
    @entries = roster_entries
    @assignment = assignment
  end

  def sort
    users_with_repo = @assignment.repos.pluck(:user_id)

    @entries.sort_by do |entry|
      next 2 if entry.user.blank?
      users_with_repo.include?(entry.user.id) ? 0 : 1
    end
  end
end
