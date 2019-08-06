# frozen_string_literal: true

class BulkApiJob < ApplicationJob
  class Error < StandardError
    class ArgumentError < Error
      def message
        "Invalid arguments. Arguments should be provided as a hash."
      end
    end

    class UserNotFound < Error
      def message
        "User performing the bulk API job must be provided."
      end
    end
  end

  queue_as :bulk_api_job

  rescue_from(GitHub::Forbidden) do
    args = arguments.first
    retries = arguments.last[:retries] if arguments.last.is_a? Hash
    arguments.last[:retries] -= 1 if retries

    self.class.perform_later(args) if retries&.positive?
  end

  before_enqueue do |job|
    args = job.arguments.first
    raise Error::ArgumentError unless args.is_a? Hash
    raise Error::UserNotFound unless (user = args[:user])
    cooldown = user.bulk_api_job_cooldown

    if cooldown.nil? || Time.zone.now > cooldown
      job.scheduled_at = Time.zone.now
      GitHubClassroom.redis.set("user_api_job:#{user.id}", (Time.zone.now + 1.hour).to_datetime)
    else
      job.scheduled_at = cooldown.to_i
      GitHubClassroom.redis.set("user_api_job:#{user.id}", (cooldown + 1.hour).to_datetime)
    end
  end
end
