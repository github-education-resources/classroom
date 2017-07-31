if Rails.env.production?
  require 'datadog/statsd'

  module GitHubClassroom
    def self.statsd
      @statd ||= ::Datadog::Statsd.new('localhost', 8125)
    end
  end
end
