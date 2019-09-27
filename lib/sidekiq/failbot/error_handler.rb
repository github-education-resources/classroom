# frozen_string_literal: true

module Sidekiq
  module Failbot
    class ErrorHandler
      class << self
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def report(exception, context_hash)
          failbot_context = {}.tap do |ctx|
            job = context_hash[:job]

            ctx[:queue] = job["queue"]
            ctx[:retry] = job["retry"]
            ctx[:jid]   = job["jid"]

            ctx[:created_at]  = Time.at(job["created_at"]).utc
            ctx[:enqueued_at] = Time.at(job["enqueued_at"]).utc
            ctx[:failed_at]   = Time.at(job["enqueued_at"]).utc

            if (retried_at = job["retried_at"])
              ctx[:retried_at] = Time.at(retried_at).utc
            end

            if (args = job["args"].first)
              ctx["job_id"] = args["job_id"]
              ctx["arguments"] = args["arguments"]
            end

            ######################
            # Production context #
            ######################

            if (git_sha = ENV["GIT_SHA"])
              ctx[:sha] = git_sha
            end

            if (git_branch = ENV["GIT_BRANCH"])
              ctx[:current_ref] = git_branch
            end

            if (release_version = ENV["HEROKU_RELEASE_VERSION"])
              ctx[:release_version] = release_version
            end
          end

          ::Failbot.report(exception, failbot_context)
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      end
    end
  end
end
