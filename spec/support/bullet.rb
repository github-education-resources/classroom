# frozen_string_literal: true

if defined?(Bullet) && Bullet.enable?
  # There's an issue with the gem that results in false positives in tests. The
  # recommendation is to disable this until it's fixed https://github.com/flyerhzm/bullet/issues/481
  Bullet.unused_eager_loading_enable = false

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
