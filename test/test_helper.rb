# frozen_string_literal: true

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('test', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

class ActiveSupport::TestCase
  include Chewy::Minitest::Helpers

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # In order to use :bypass strategy for Chewy, we need to wrap every
  # test block, setup block, and teardown block with Chewy.strategy(:bypass)
  #
  # See https://github.com/toptal/chewy#rails-application-strategies-integration
  #
  def self.test(test_name, &block)
    return super if block.nil?

    super(test_name) do
      # Wrap every test in Chewy :bypass strategy
      Chewy.strategy(:bypass) do
        instance_eval(&block)
      end
    end
  end

  def before_setup
    # Set the OmniAuth mock config back to it's original state
    # between tests to avoid pollution.
    reset_omniauth

    Chewy.strategy(:bypass) do
      # Enable VCR and configure a cassette named
      # based on the test method and grab anything in the setup block.
      #
      # This means that a test written like this:
      #
      # class OrderTest < ActiveSupport::TestCase
      #   test 'user can place an order' do
      #     ...
      #   end
      # end
      #
      # will automatically use VCR to intercept and record/play back any external
      # HTTP requests using `fixtures/cassettes/order_test/test_user_can_place_order.json`.
      base_path = self.class.name.underscore
      VCR.insert_cassette(base_path + '/' + name)

      Bullet.start_request

      super if defined?(super)
    end
  end

  def after_teardown
    Chewy.strategy(:bypass) do
      super if defined?(super)
    end

    VCR.eject_cassette

    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end

  # Add more helper methods to be used by all tests here...

  # Public: Generate a random unsed integer for a given model to use
  # as an attribute.
  #
  # subject   - The class of the object you want to find a unique attribute for.
  # attribute - The Integer type attribute for which we are searching against.
  #
  # Examples:
  #
  #   unique_integer_attribute(User, :uid)
  #   # => 42
  #
  # Returns an Integer.
  def unique_integer_attribute(subject, attribute)
    id = nil

    loop do
      id = SecureRandom.random_number(1_000_000)
      break if subject.find_by(attribute => id).blank?
    end

    id
  end
end
