module Classroom
  def self.redis
    redis_url = unless Rails.env.production?
                  "redis://localhost:6379/0"
                else
                  ENV['REDIS_PROVIDER']
                end

    @redis ||= Redis.new(url: redis_url)
  end
end
