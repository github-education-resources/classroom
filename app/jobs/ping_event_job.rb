# frozen_string_literal: true

# Documentation: https://developer.github.com/webhooks/#ping-event
class PingEventJob < ApplicationJob
  queue_as :github_event

  # rubocop:disable GuardClause
  def perform(payload_body)
    if (organization = Organization.find_by(github_id: payload_body["organization"]["id"]))
      organization.update_attributes!(is_webhook_active: true)
    end
  end
  # rubocop:enable GuardClause
end
