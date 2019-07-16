# frozen_string_literal: true

module GitHubClassroom
  def self.lti_tool(options = {})
    if options[:lti_configuration].present?
      lti_configuration = options.delete :lti_configuration

      options[:consumer_key] = lti_configuration.consumer_key
      options[:shared_secret] = lti_configuration.shared_secret
    end

    client_options = {
      consumer_key:  nil,
      shared_secret: nil
    }.merge!(options)

    LTI::ToolProvider.new(client_options)
  end
end
