# frozen_string_literal: true

module GitHubClassroom
  def self.github_client(options = {})
    options[:user_agent] = "GitHub Classroom"

    unless options.key?(:access_token)
      options[:client_id] = Rails.application.secrets.github_client_id
      options[:client_secret] = Rails.application.secrets.github_client_secret
    end

    if enterprise_instance?
      options[:api_endpoint] = "https://#{Rails.application.secrets.github_enterprise_hostname}/api/v3"
    end

    Octokit::Client.new(options)
  end

  def self.enterprise_instance?
    Rails.application.secrets.github_enterprise_hostname.present?
  end
end
