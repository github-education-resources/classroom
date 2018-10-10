# frozen_string_literal: true

# Runs a migration on possible locked (stuck) invite_statuses to change their status to "unaccepted"
task locked_invite_status_migration: :environment do
  invite_statuses_touched = 0
  InviteStatus
    .where(status: InviteStatus::LOCKED_STATUSES)
    .find_in_batches(batch_size: 100) do |invite_statuses|
      invite_statuses.each do |invite_status|
        time_difference = Time.now.utc - invite_status.updated_at.utc
        if time_difference > 1.hour
          # if invite complete and webhook was missed
          #   update to complete state
          # else 
          puts("=> InviteStatus id: #{invite_status.id} – \"#{invite_status.status}\" => \"unaccepted\"")
          invite_status.unaccepted!
          invite_statuses_touched += 1
        end
      end
    end

  puts("=> Number of InviteStatuses touched: #{invite_statuses_touched}")
end
