# frozen_string_literal: true

if defined?(Bullet) && Bullet.enable?
  RSpec.configure do |config|
    config.before(:each) do
      Bullet.start_request
    end

    config.around(:each, type: :controller) do |example|
      Bullet.unused_eager_loading_enable = false
      example.run
      Bullet.unused_eager_loading_enable = true
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end
end
