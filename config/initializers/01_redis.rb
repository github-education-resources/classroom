module Classroom
  REDIS_URL = ENV['REDIS_PROVIDER'] || 'redis://localhost:6379/0'

  def self.redis
    @redis ||= Redis.new(url: REDIS_URL)
  end
end
