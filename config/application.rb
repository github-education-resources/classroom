# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

# From https://github.com/rails/rails/blob/master/railties/lib/rails/all.rb
require 'rails'

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  active_job/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError # rubocop:disable Lint/HandleExceptions
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GitHubClassroom
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Available locales
    I18n.available_locales = [:en]

    # Add bower assets to the path
    root.join('vendor', 'assets', 'bower_components').to_s.tap do |bower_path|
      config.sass.load_paths << bower_path
      config.assets.paths << bower_path
    end

    # Append directories to autoload paths
    config.eager_load_paths += [
      'lib'
    ].map { |path| Rails.root.join(path).to_s }

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

          if status == 'green'
            'ok'
          else
            raise "Elasticsearch status is #{status}"
          end
        end
      end
    end
  end
end
