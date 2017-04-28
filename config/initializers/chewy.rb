# frozen_string_literal: true

# Set Chewy to log level INFO in production
if Rails.env.production?
  Rails.application.config.after_initialize do
    Chewy.logger = Logger.new(STDOUT)
    Chewy.logger.level = Logger::INFO
  end
end
