ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda'

# Better Minitest output
require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new,
  ENV,
  Minitest.backtrace_filter)

OmniAuth.config.test_mode = true

class ActiveSupport::TestCase
  fixtures :all
end
