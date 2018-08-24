class GroupRepositoryCreationStatusChannel < ApplicationCable::Channel
  def self.channel(group_id:, invitation_id:)
    "#{channel_name}_#{group_id}_#{invitation_id}"
  end

  def subscribed
    stream_from self.class.channel(group_id: params[:group_id], invitation_id: params[:invitation_id])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
