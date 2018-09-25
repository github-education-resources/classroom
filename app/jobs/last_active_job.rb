# frozen_string_literal: true

class LastActiveJob < ApplicationJob
  queue_as :last_active

  # Public: Update the last time the User was active.
  #
  # user_id          - The Integer id of the User that was active.
  # time_last_active - The Integer representing the time the User was current.
  #
  # returns nothing.
  def perform(user_id, time_last_active)
    # Do another lookup to make sure the User is still around
    return true unless (user = User.find_by(id: user_id))

    time_last_active = Time.zone.at(time_last_active)
    user.update_columns(last_active_at: time_last_active) # rubocop:disable Rails/SkipsModelValidations
    User.update_index("user#user") { user }
  end
end
