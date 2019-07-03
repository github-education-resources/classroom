# frozen_string_literal: true

module GitHubClassroom
  def self.lti_provider(options = {})
    client_options = {
      consumer_key:  nil,
      shared_secret: nil,
      redis_store: GitHubClassroom.redis
    }.merge!(options)

    GitHubClassroom::LtiProvider.new(client_options)
  end
end


