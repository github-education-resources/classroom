# frozen_string_literal: true
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  # Make sure the cache is clear when the tests
  # suite starts and before every test
  config.before(:suite) do
    begin
      Rails.cache.clear
    ensure
      Rails.cache.clear
    end
  end
end
