# frozen_string_literal: true

class BulkApiJob < ApplicationJob
  class Error < StandardError
    class JobAlreadyRunning < Error
      def message
        "User is already running a bulk API job. Users can only run one bulk job at a time."
      end
    end

    class MissingUser < Error
      def message
        "First argument in perform method must be the User performing the job."
      end
    end
  end

  queue_as :bulk_api_job

  rescue_from(GitHub::Forbidden) do
    retries = arguments.last[:retries] if arguments.last.is_a? Hash
    arguments.last[:retries] -= 1 if retries

    self.class.perform_later(*arguments) if retries && retries.positive?
  end

  before_enqueue do |job|
    user = job.arguments.first
    raise Error::MissingUser unless user.is_a? User
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
