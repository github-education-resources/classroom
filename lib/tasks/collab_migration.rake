# frozen_string_literal: true

require_relative "../collab_migration"

task collab_migration: :environment do
  User.find_in_batches(batch_size: 100) do |users|
    users.each do |user|
      user.repo_accesses.each do |repo_access|
        collab_migrator = CollabMigration.new(repo_access)
        collab_migrator.migrate
      end
    end
  end
end
