# frozen_string_literal: true

require "bullet/version"

unless Bullet::VERSION == "5.7.6"
  raise <<~ERROR
    Check if Bullet.unused_eager_loading_enable = false is still needed in this version of Bullet
    https://github.com/flyerhzm/bullet/issues/147
  ERROR
end

Bullet.unused_eager_loading_enable = false

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
