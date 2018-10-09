# frozen_string_literal: true

# rubocop:disable Rails/SkipsModelValidations

# rubocop:disable Metrics/BlockLength
task global_relay_id_backfill: :environment do
  puts "Backfilling Global Relay ID's to Users, Orgs, AssignmentRepos, and GroupAssignmentRepos."

  users_updated = 0
  puts "Updating users..."

  # Users
  User.where(github_global_relay_id: nil).find_in_batches(batch_size: 500) do |users|
    users_updated += users.length
    users.each do |user|
      user.update_columns(github_global_relay_id: generate_gid("User", user.uid))
    end
  end

  organizations_updated = 0
  puts "Updating orgs..."

  # Organizations
  Organization.where(github_global_relay_id: nil).find_in_batches(batch_size: 500) do |orgs|
    organizations_updated += orgs.length
    orgs.each do |org|
      org.update_columns(github_global_relay_id: generate_gid("Organization", org.github_id))
    end
  end

  assignment_repos_updated = 0
  puts "Updating AssignmentRepos..."

  # AssignmentRepos
  AssignmentRepo.where(github_global_relay_id: nil).find_in_batches(batch_size: 500) do |repos|
    assignment_repos_updated += repos.length
    repos.each do |repo|
      repo.update_columns(github_global_relay_id: generate_gid("Repository", repo.github_repo_id))
    end
  end

  group_assignment_repos_updated = 0
  puts "Updating GroupAssignmentRepos..."

  # GroupAssignmentRepos
  GroupAssignmentRepo.where(github_global_relay_id: nil).find_in_batches(batch_size: 500) do |repos|
    group_assignment_repos_updated += repos.length
    repos.each do |repo|
      repo.update_columns(github_global_relay_id: generate_gid("Repository", repo.github_repo_id))
    end
  end

  puts "Done! We backfilled global relay IDs to:"
  puts "#{users_updated} users"
  puts "#{organizations_updated} organizations"
  puts "#{assignment_repos_updated} assignment repos"
  puts "#{group_assignment_repos_updated} group assignment repos"
end
# rubocop:enable Metrics/BlockLength

# rubocop:enable Rails/SkipsModelValidations

def generate_gid(type, id)
  Base64.strict_encode64(["0", type.length, ":", type, id.to_s].join)
end
