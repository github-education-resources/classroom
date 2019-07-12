# frozen_string_literal: true

module GitHubClassroom
  def self.lti_message_store(options = {})
    client_options = {
      consumer_key:  nil,
      redis_store: GitHubClassroom.redis
    }.merge!(options)

    LTI::MessageStore.new(client_options)
  end
end
