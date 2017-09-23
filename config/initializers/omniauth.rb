# frozen_string_literal: true

options.tap do |opts|
  opts[:scope] = 'user:email,repo,delete_repo,admin:org,admin:org_hook'

  if GitHubClassroom.enterprise_instance?
    hostname = Rails.application.secrets.github_enterprise_hostname
    opts[:site]          = "https://#{hostname}/api/v3"
    opts[:authorize_url] = "https://#{hostname}/login/oauth/authorize"
    opts[:token_url]     = "https://#{hostname}/oauth/access_token"
  end

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :github,
    Rails.application.secrets.github_client_id,
    Rails.application.secrets.github_client_secret,
    { client_options: options }
  end
end
