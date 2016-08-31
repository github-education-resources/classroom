module GitHubClassroom
  REDIS_URL = ENV['REDIS_URL'] || 'redis://localhost:6379/0'

  def self.redis
    @redis ||= Redis.new(url: REDIS_URL)
  end
end
