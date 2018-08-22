# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "csv"
require "graphql/client/http"
require "graphql/client/railtie"
require 'graphql/batch'
require_relative "../app/graphql/github_classroom_schema"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

ENV["FAILBOT_BACKEND"] ||= "memory"

# report exceptions using Failbot
require "failbot_rails"
FailbotRails.setup("classroom#{'-staging' if Rails.env.staging?}")

module GitHubClassroom
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Available locales
    I18n.available_locales = [:en]

    # Append directories to autoload paths
    config.eager_load_paths += %w[lib].map { |path| Rails.root.join(path).to_s }

    # Configure the generators
    config.generators do |g|
      g.test_framework :rspec, fixture: false
    end

    # GC Profiler for analytics
    GC::Profiler.enable

    # Use SideKiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Health checks endpoint for monitoring
    if ENV["PINGLISH_ENABLED"] == "true"
      config.middleware.use Pinglish do |ping|
        ping.check :db do
          ActiveRecord::Base.connection.tables.size
          "ok"
        end

        ping.check :memcached do
          Rails.cache.dalli.checkout.alive!
          "ok"
        end

        ping.check :redis do
          Sidekiq.redis(&:ping)
          "ok"
        end

        ping.check :elasticsearch do
          status = Chewy.client.cluster.health["status"] || "unavailable"

          if status == "green" # rubocop:disable Style/GuardClause
            "ok"
          else
            raise "Elasticsearch status is #{status}"
          end
        end
      end
    end
  end

  class ClassroomExecutor
    # TODO: Patch octokit in here to raise if REST API calls are made during GraphQL query resolution
    def self.execute(document:, operation_name: nil, variables: {}, context: {})
      unless context[:current_user] && context[:current_user].is_a?(::User)
        raise GitHubClassroomSchema::GraphQLError.new "A current_user must be provided to execute a GraphQL Query"
      end

      GitHubClassroomSchema.execute(document.to_query_string, variables: variables, context: context, operation_name: operation_name)
    end
  end

  ClassroomClient = GraphQL::Client.new(
    schema: GitHubClassroomSchema.graphql_definition,
    execute: ClassroomExecutor
  )

  GitHubHTTPAdapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      {
        "Authorization" => "Bearer #{context[:current_user].token}"
      }
    end
  end

  GitHubClient = GraphQL::Client.new(
    schema: Application.root.join("db/schema.json").to_s,
    execute: GitHubHTTPAdapter
  )

  GitHubClient.allow_dynamic_queries = true
end

Rails.application.config.graphql.client = GitHubClassroom::ClassroomClient
