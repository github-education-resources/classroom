# frozen_string_literal: true

module GitHubClassroom
  def self.lti_provider(options = {})
    client_options = {
      consumer_key:  nil,
      redis_store: GitHubClassroom.redis,
      shared_secret: nil # TODO: something like LMSConfiguration.find_by(consumer_key: options[:consumer_key])
    }.merge!(options)

    GitHubClassroom::LtiProvider.new(client_options)
  end
end


