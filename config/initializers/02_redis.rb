# frozen_string_literal: true

module GitHubClassroom
  REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:9736/0")

  def self.redis
    @redis ||= Redis.new(url: REDIS_URL)
  end
end
