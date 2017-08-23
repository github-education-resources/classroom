# frozen_string_literal: true

require "datadog/statsd" if Rails.env.production?
require "./lib/github_classroom/null_statsd"

module GitHubClassroom
  APP_NAME = ENV["HEROKU_APP_NAME"] || "github-classroom"
  DYNO = ENV["DYNO"] || 1

  def self.statsd
    @statsd ||= if Rails.env.production?
                  ::Datadog::Statsd.new("localhost", 8125, tags: ["application:#{APP_NAME}", "dyno_id:#{DYNO}"])
                else
                  ::GitHubClassroom::NullStatsD.new
                end
  end
end

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |_name, _start, _finish, _id, payload|
  next if payload[:path].match? %r{\A\/peek/}

  view_time = payload[:view_runtime]
  db_time   = payload[:db_runtime]
  next unless view_time.respond_to?(:+) && db_time.respond_to?(:+)

  total_time = view_time + db_time

  GitHubClassroom.statsd.timing("request.response_time", total_time)
end
