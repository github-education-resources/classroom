# frozen_string_literal: true

class AddStudentsToRosterChannel < ApplicationCable::Channel
  def self.channel(user_id:, roster_id:)
    "#{channel_name}_#{user_id}_#{roster_id}"
  end

  def subscribed
    stream_from self.class.channel(roster_id: params[:roster_id], user_id: current_user.id)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
