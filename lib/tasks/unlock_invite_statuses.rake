# frozen_string_literal: true

# This task is run inside Heroku Scheduler at regular intervals.
# See Heroku Scheduler docs at: https://devcenter.heroku.com/articles/scheduler

# Unlocks `InviteStatus` and `GroupInviteStatus` records that have been locked (stuck)
# for more than `UnlockInviteStatusesService::TIME`.
# This task sets locked statuses to the "unaccepted" status.
# Reports any unlocked statuses to Failbot.
task unlock_invite_statuses: :environment do
  task_stats = UnlockInviteStatusesService.unlock_invite_statuses
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
