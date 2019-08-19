# frozen_string_literal: true

module OmniAuth
  module Strategies
    autoload :Lti, Rails.root.join("lib", "omniauth", "strategies", "lti")
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  options = { scope: "user:email,repo,delete_repo,admin:org,admin:org_hook" }

  if GitHubClassroom.enterprise_instance?
    hostname = Rails.application.secrets.github_enterprise_hostname
    options[:client_options] = {
      site: "https://#{hostname}/api/v3",
      authorize_url: "https://#{hostname}/login/oauth/authorize",
      token_url: "https://#{hostname}/login/oauth/access_token",
    }
  end

  provider :github,
    Rails.application.secrets.github_client_id,
    Rails.application.secrets.github_client_secret,
    options

  provider :lti,
    callback_path: "/auth/lti/launch",
    setup: true
end
