# frozen_string_literal: true

if defined?(Bullet) && Bullet.enable?
  RSpec.configure do |config|
    config.before(:each) do
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end
end
