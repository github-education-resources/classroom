# frozen_string_literal: true

# Unlocks `InviteStatus` and `GroupInviteStatus` records that have been locked (stuck) for more than an hour.
# This task sets locked statuses to the "unaccepted" status.
task unlock_invite_statuses: :environment do
  task_stats = {}
  [InviteStatus, GroupInviteStatus].each do |invite_status_model|
    model_name = invite_status_model.to_s.underscore
    task_stats[model_name] = {}
    task_stats["total_#{model_name.pluralize}"] = 0
    invite_status_model::LOCKED_STATUSES.each do |status, _|
      task_stats[model_name][status] = 0
    end

    invite_status_model
      .where(status: invite_status_model::LOCKED_STATUSES)
      .find_in_batches(batch_size: 100) do |invite_statuses|
        invite_statuses.each do |invite_status|
          time_difference = Time.now.utc - invite_status.updated_at.utc
          next unless time_difference > 1.hour
          task_stats[model_name][invite_status.status] += 1
          invite_status.unaccepted!
          task_stats["total_#{model_name.pluralize}"] += 1
        end
      end
  end

  print_stats(task_stats)
end

def print_stats(task_stats)
  puts("=====================================")
  puts("---- Unlock InviteStatuses Stats ----")
  puts("Number of invite statuses unlocked:")
  print("=> ")
  pp task_stats
  puts("=====================================")
end
