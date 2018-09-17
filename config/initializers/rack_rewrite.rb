# frozen_string_literal: true

# URL for Nuts Server deployed on Heroku, redirects download/update requests to latest release
# on GitHub Releases with platform parameters
RELEASE_SERVER_URL = "http://classroom-assistant-releases.herokuapp.com"

Rails.application.config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
  r301 %r{/assistant/download(.*)}, "#{RELEASE_SERVER_URL}/download$1"
  r301 %r{/assistant/update(.*)}, "#{RELEASE_SERVER_URL}/update$1"
end
