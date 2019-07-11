# frozen_string_literal: true

module OmniAuth
  module Strategies
    autoload :Lti, Rails.root.join("lib", "omniauth", "strategies", "lti")
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.secrets.github_client_id,
    Rails.application.secrets.github_client_secret,
    scope: "user:email,repo,delete_repo,admin:org,admin:org_hook"

  provider :lti,
    callback_path: "/auth/lti/launch",
    setup: true
end
