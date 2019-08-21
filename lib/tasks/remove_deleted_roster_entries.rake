# frozen_string_literal: true

task remove_deleted_roster_entries: :environment do
  puts "Removing roster entries connected to deleted rosters"

  BATCH_SIZE = 100

  roster_entries_deleted = 0
  batch_num = 1

  non_existing_rosters = RosterEntry.where.not(roster_id: Roster.pluck(:id)).pluck(:roster_id).uniq

  non_existing_rosters.each do |roster_id|
    roster_entries_to_delete = RosterEntry.where(roster_id: roster_id)

    roster_entries_to_delete.find_in_batches(batch_size: BATCH_SIZE) do |roster_entries|
      puts "Updating batch #{batch_num}, starting with roster entry ID #{roster_entries.first.id}"

      roster_entries.each do |roster_entry|
        roster_entry.destroy!
      end

      roster_entries_deleted += roster_entries.length
      batch_num += 1
    end
  end

  puts("Done! #{roster_entries_deleted} roster entries have been deleted.")
end