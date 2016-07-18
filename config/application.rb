require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Classroom
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add bower assets to the path
    root.join('vendor', 'assets', 'bower_components').to_s.tap do |bower_path|
      config.sass.load_paths << bower_path
      config.assets.paths << bower_path
    end

    # Append directories to autoload paths
    config.autoload_paths += Dir["#{Rails.root}/lib"]

    # Configure the generators
    config.generators do |g|
      g.test_framework :rspec, fixture: false
    end

    # GC Profiler for analytics
    GC::Profiler.enable

    # Use SideKiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Health checks endpoint for monitoring
    if ENV['PINGLISH_ENABLED'] == 'true'
      config.middleware.use Pinglish do |ping|
        ping.check :db do
          ActiveRecord::Base.connection.tables.size
          'ok'
        end

        ping.check :memcached do
          Rails.cache.dalli.checkout.alive!
          'ok'
        end

        ping.check :redis do
          Sidekiq.redis(&:ping)
          'ok'
        end

        ping.check :elasticsearch do
          status = Chewy.client.cluster.health['status'] || 'unavailable'
          return 'ok' if status == 'green'
          raise "Elasticsearch status is #{status}"
        end
      end
    end
  end
end
