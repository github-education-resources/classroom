# frozen_string_literal: true

require "datadog/statsd" if Rails.env.production?

class StubStatsd
  def increment(stat, opts = {}); end
end

module GitHubClassroom
  APP_NAME = ENV["HEROKU_APP_NAME"] || "github-classroom"
  DYNO = ENV["DYNO"] || 1

  def self.statsd
    @statsd ||= if Rails.env.production?
                  ::Datadog::Statsd.new("localhost", 8125, tags: ["application:#{APP_NAME}", "dyno_id:#{DYNO}"])
                else
                  ::StubStatsd.new
                end
  end
end
