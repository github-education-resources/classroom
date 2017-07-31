# frozen_string_literal: true

require "datadog/statsd"

class StubStatsd
  def increment(stat, opts = {}); end
end

module GitHubClassroom
  APP_NAME = ENV["HEROKU_APP_NAME"] || "github-classroom"

  def self.statsd
    @statsd ||= if Rails.env.production?
                  ::Datadog::Statsd.new("localhost", 8125, tags: ["application:#{APP_NAME}", "dyno_id:#{ENV['DYNO']}"])
                else
                  ::StubStatsd.new
                end
  end
end
