# frozen_string_literal: true

module GitHubClassroom
  def self.github_client(options = {})
    options[:user_agent] = "GitHub Classroom"

    unless options.key?(:access_token)
      options[:client_id] = Rails.application.secrets.github_client_id
      options[:client_secret] = Rails.application.secrets.github_client_secret
    end

    if enterprise?
      options[:api_endpoint] = "#{Rails.application.secrets.github_enterprise_url}/api/v3"
    end

    Octokit::Client.new(options)
  end

  def self.enterprise?
    return false if Rails.env.test?

    Rails.application.secrets.github_enterprise_url.present?
  end

  def self.github_url
    if enterprise?
      Rails.application.secrets.github_enterprise_url
    else
      "https://github.com"
    end
  end
end
