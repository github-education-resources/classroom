# frozen_string_literal: true

module GitHubClassroom
  def self.flipper
    @flipper ||= flipper!
  end

  def self.flipper!
    adapter = if Rails.env.test?
                require "flipper/adapters/memory"
                Flipper::Adapters::Memory.new
              else
                namespaced_client = Redis::Namespace.new(:flipper, redis: GitHubClassroom.redis)
                Flipper::Adapters::Redis.new(namespaced_client)
              end

    Flipper.new(adapter)
  end
end

# Flipper group for staff
Flipper.register(:staff) do |user|
  user.respond_to?(:staff?) && user.staff?
end
