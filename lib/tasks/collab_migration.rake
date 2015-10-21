require_relative '../collab_migration'

task collab_migration: :environment do
  User.all.each do |user|
    user.repo_accesses.each do |repo_access|
      collab_migrator = CollabMigration.new(repo_access)
      collab_migrator.migrate
    end
  end
end
