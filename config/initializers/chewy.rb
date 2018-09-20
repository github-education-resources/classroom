# frozen_string_literal: true

## Configure chewy

# Use ActiveJob config for async index updates.
Chewy.strategy(:active_job)

# Chewy wraps controller actions in the atomic strategy by default.
# We change this to use ActiveJob here. Makes index updates async, outside
# of the request.
Chewy.request_strategy = :active_job
Chewy.root_strategy = :active_job

# Set Chewy to log level INFO in production
if Rails.env.production?
  Rails.application.config.after_initialize do
    Chewy.logger = Logger.new(STDOUT)
    Chewy.logger.level = Logger::INFO
  end
end
