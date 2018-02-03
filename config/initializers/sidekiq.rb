# frozen_string_literal: true

require "sidekiq/failbot/error_handler"

Sidekiq.configure_server do |config|
  config.error_handlers << proc { |ex, ctx_hash| Sidekiq::Failbot::ErrorHandler.report(ex, ctx_hash) }

  # Add chewy middleware from lib/sidekiq/chewy_middleware.rb
  config.server_middleware do |chain|
    chain.add Sidekiq::ChewyMiddleware, :atomic
  end
end
