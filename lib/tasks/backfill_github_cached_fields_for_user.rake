# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
task backfill_github_cached_fields_for_user: :environment do
  puts "Backfilling GitHub-cached fields for Users"

  BATCH_SIZE = 500

  users_updated = 0
  batch_num = 1


  users_to_update = User.where(github_login: nil)
  puts "There are #{users_to_update.count} users to update."

  users_to_update.find_in_batches(batch_size: BATCH_SIZE) do |users|
    puts "Updating batch #{batch_num}, starting with user ID #{users.first.id}"

    users_updated += users.length
    batch_num += 1

    users.each do |user|
      user.github_user.login # The cache will fetch all cacheable fields if an API call is required.
    end
  end

  puts "Done! #{users_updated} users have been updated."
end
# rubocop:enable Metrics/BlockLength
