# frozen_string_literal: true

Sidekiq.configure_server do |config|
  # Add chewy middleware from lib/sidekiq/chewy_middleware.rb
  config.server_middleware do |chain|
    chain.add Sidekiq::ChewyMiddleware, :atomic
  end
end
