# frozen_string_literal: true
RSpec.configure do |config|
  # Make sure the cache is clear before
  # every test.
  config.before(:each) do
    Rails.cache.clear
  end
end
