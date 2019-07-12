# frozen_string_literal: true

module GitHubClassroom
  def self.lti_message_store(options = {})
    if options[:lti_configuration].present?
      options[:consumer_key] = options[:lti_configuration].consumer_key
      options.delete(:lti_configuration)
    end

    client_options = {
      consumer_key:  nil,
      redis_store: GitHubClassroom.redis
    }.merge!(options)

    LTI::MessageStore.new(client_options)
  end
end
