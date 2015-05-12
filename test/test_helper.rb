ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda'

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new,
  ENV,
  Minitest.backtrace_filter)

OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
  'provider'=> 'github',
  'uid'=> '8675309',

  'info'=>
  {
    'nickname' => 'testuser',
    "email"    => 'testuser@gmail.com',
    'name'     => 'Test User',
  },

  'credentials' => { 'token' => 'some-token' }
})

class ActiveSupport::TestCase
  fixtures :all
end
