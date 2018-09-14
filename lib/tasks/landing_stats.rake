# frozen_string_literal: true

# Runs a migration on possible locked (stuck) invite_statuses to change their status to "unaccepted"
task landing_stats: :environment do
  user_count = User.count
  repo_count = AssignmentRepo.count + GroupAssignmentRepo.count

  TickerStat.create user_count: user_count, repo_count: repo_count
end
