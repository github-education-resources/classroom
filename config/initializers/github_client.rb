# frozen_string_literal: true

module GitHubClassroom
  def self.github_client(options = {})
    client_options = options.tap do |opts|
      opts[:user_agent] = "GitHub Classroom"

      unless options.key?(:access_token)
        opts[:client_id]     = Rails.application.secrets.github_client_id
        opts[:client_secret] = Rails.application.secrets.github_client_secret
      end

      if enterprise_instance?
        opts[:api_endpoint] = "https://#{Rails.application.secrets.github_enterprise_hostname}/api/v3"
      end
    end
    Octokit::Client.new(client_options)
  end

  def self.enterprise_instance?
    Rails.application.secrets.enterprise_enabled == true
  end
end
