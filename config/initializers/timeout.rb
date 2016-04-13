Rack::Timeout.timeout = 25

# Rack::Timeout::Logger in info mode is very noisy. Setting to WARN so that
# Rack::Timeout request timing info is not logged for every request.
Rack::Timeout::Logger.logger = Rails.logger
Rack::Timeout::Logger.level = Logger::Severity::WARN
