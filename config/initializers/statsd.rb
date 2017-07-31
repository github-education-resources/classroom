# frozen_string_literal: true

require "datadog/statsd"

class StubStatsd
  def increment; end
end

module GitHubClassroom
  def self.statsd
    @statsd ||= if Rails.env.production?
                  ::Datadog::Statsd.new("localhost", 8125)
                else
                  ::StubStatsd.new
                end
  end
end
