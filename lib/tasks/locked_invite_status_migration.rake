# frozen_string_literal: true

# Runs a migration on possible locked (stuck) invite_statuses to change their status to "unaccepted"
task locked_invite_status_migration: :environment do
  InviteStatus
    .where(status: InviteStatus::LOCKED_STATUSES)
    .find_in_batches(batch_size: 100) do |invite_statuses|
      invite_statuses.each do |invite_status|
        time_difference = Time.now.utc - invite_status.updated_at.utc
        if time_difference > 1.hour
          puts("InviteStatus id: #{invite_status.id} – \"#{invite_status.status}\" => \"unaccepted\"")
          invite_status.unaccepted!
        end
      end
    end
end
