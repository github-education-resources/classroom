# frozen_string_literal: true

if Rails.env.production?
  Airbrake.configure do |config|
    config.project_id  = ENV.fetch("AIRBRAKE_PROJECT_ID")  { "unset-project-id" }
    config.project_key = ENV.fetch("AIRBRAKE_PROJECT_KEY") { "unset-api-key"    }

    config.environment = Rails.env || "development"
    config.ignore_environments = %w[development test]
    config.root_directory = Rails.root
  end

  Airbrake.add_filter do |notice|
    notice[:environment][:HEROKU_DYNO] = ENV["DYNO"]       if ENV["DYNO"]
    notice[:environment][:GIT_BRANCH]  = ENV["GIT_BRANCH"] if ENV["GIT_BRANCH"]
    notice[:environment][:GIT_SHA]     = ENV["GIT_SHA"]    if ENV["GIT_SHA"]
  end
end
