# frozen_string_literal: true

module GitHubClassroom
  def self.lti_message_store(options = {})
    client_options = {
      consumer_key:  nil,
      shared_secret: nil,
      redis_store: GitHubClassroom.redis
    }.merge!(options)

    GitHubClassroom::LtiMessageStore.new(client_options)
  end
end
