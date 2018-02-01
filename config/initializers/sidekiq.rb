# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: GitHubClassroom::REDIS_URL }

  # Add chewy middleware from lib/sidekiq/chewy_middleware.rb
  config.server_middleware do |chain|
    chain.add Sidekiq::ChewyMiddleware, :atomic
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: GitHubClassroom::REDIS_URL }
end
