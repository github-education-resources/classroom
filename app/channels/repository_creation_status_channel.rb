class RepositoryCreationStatusChannel < ApplicationCable::Channel
  CHANNEL_ID = "repository_creation_status"

  def subscribed
    stream_from CHANNEL_ID
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
