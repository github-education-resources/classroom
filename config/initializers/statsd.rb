require 'datadog/statsd'

class StubStatsd
  def increment; end
end

module GitHubClassroom
  def self.statsd
    if Rails.env.production?
      @statsd ||= ::Datadog::Statsd.new("localhost", 8125)
    else
      @stats ||= ::StubStatsd.new
    end
  end
end
