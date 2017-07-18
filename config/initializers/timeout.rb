# frozen_string_literal: true

# The rack-timeout gem inserts itself into the Rails middleware automatically
# upon requiring. We wait to require it until here so that we may skip using it
# in the development and test environments.
unless Rails.env.test? || Rails.env.development?
  require "rack-timeout"

  # Raise an error when the request time exceeds 25 seconds.
  Rack::Timeout.timeout = 25

  # Rack::Timeout::Logger in info mode is very noisy. Setting to WARN so that
  # Rack::Timeout request timing info is not logged for every request.
  Rack::Timeout::Logger.logger = Rails.logger
  Rack::Timeout::Logger.level = Logger::Severity::WARN
end
