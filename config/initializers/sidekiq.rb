# frozen_string_literal: true

require "sidekiq/failbot/error_handler"

Sidekiq.configure_server do |config|
  config.redis = { url: GitHubClassroom::REDIS_URL }

  config.error_handlers << proc { |ex, ctx_hash| Sidekiq::Failbot::ErrorHandler.report(ex, ctx_hash) }
end

Sidekiq.configure_client do |config|
  config.redis = { url: GitHubClassroom::REDIS_URL }
end
