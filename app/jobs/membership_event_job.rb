# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#membershipevent
class MembershipEventJob < ApplicationJob
  queue_as :github_event
  def perform(payload_body)
    return true unless payload_body["action"] == "removed"

    github_user_id = payload_body.dig("member", "id")
    github_organization_id = payload_body.dig("organization", "id")

    organization = Organization.find(github_organization_id)
    user = organization.users.find_by(id: github_user_id)
    return true if user.nil?

    user.update_attributes(deleted_at: Time.zone.now)
    DestroyResourceJob.perform_later(current_organization)
    organization.save
  end
end
