# frozen_string_literal: true
class LastActiveJob < ApplicationJob
  queue_as :last_active

  # Public: Update the last time the User was active.
  #
  # user             - The User that was active.
  # time_last_active - The Integer representing the time the User was current.
  #
  # returns nothing.
  def perform(user, time_last_active)
    time_last_active = Time.zone.at(time_last_active)
    user.update_columns(last_active_at: time_last_active)
    User.update_index('stafftools#user') { user }
  end
end
