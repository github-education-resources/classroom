# frozen_string_literal: true

class GroupRepositoryCreationStatusChannel < ApplicationCable::Channel
  def self.channel(group_id:, group_assignment_id:)
    "#{channel_name}_#{group_id}_#{group_assignment_id}"
  end

  def subscribed
    stream_from self.class.channel(group_id: params[:group_id], group_assignment_id: params[:group_assignment_id])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
