# frozen_string_literal: true

task backfill_lms_user_ids: :environment do
  puts "Backfilling lms_user_ids from google_user_ids"

  BATCH_SIZE = 50

  roster_entries_updated = 0
  batch_num = 1

  rosters_to_update = RosterEntry.where("google_user_id IS NOT NULL")

  rosters_to_update.find_in_batches(batch_size: BATCH_SIZE) do |roster_entries|
    puts "Updating batch #{batch_num}, starting with roster entry ID #{roster_entries.first.id}"

    roster_entries.each do |roster_entry|
      google_user_id = roster_entry.google_user_id
      roster_entry.update(lms_user_id: google_user_id)
    end

    roster_entries_updated += roster_entries.length
    batch_num += 1
  end

  puts "Done! #{roster_entries_updated} rosters have been updated."
end
