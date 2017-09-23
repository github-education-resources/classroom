# frozen_string_literal: true

module GitHubClassroom
  def self.github_client(options = {})
    client_options = {}.tap do |opts|
      opts[:user_agent]    = "GitHub Classroom"
      opts[:auto_paginate] = true

      if options.has_key?(:access_token)
        opts[:access_token] = options[:access_token]
      else
        opts[:client_id]     = Rails.application.secrets.github_client_id
        opts[:client_secret] = Rails.application.secrets.github_client_secret
      end

      if enterprise_instance?
        api_endpoint = "https://#{Rails.application.secrets.github_enterprise_hostname}/api/v3"
        opts[:api_endpoint] = api_endpoint
      end
    end

    Octokit::Client.new(client_options)
  end

  def self.enterprise_instance?
    Rails.application.secrets.enterprise_enabled == true
  end
end
