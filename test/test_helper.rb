ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/spec'

# Require all support files
Dir["#{Rails.root}/test/support/**/*.rb"].each {|file| require file }

class ActiveSupport::TestCase
  fixtures :all
end

class ActionController::TestCase
  extend Minitest::Spec::DSL
end
