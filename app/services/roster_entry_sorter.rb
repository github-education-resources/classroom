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
    users_with_repo = @assignment.repos.map(&:user_id)

    @entries.sort_by { |entry|
      if entry.user.present?
        if users_with_repo.include? entry.user.id
          0
        else
          1
        end
      else
        2
      end
    }
  end


end
