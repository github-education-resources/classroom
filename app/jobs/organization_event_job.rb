# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#organizationevent
class OrganizationEventJob < ApplicationJob
  queue_as :github_event

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def perform(payload_body)
    return true unless payload_body.dig("action") == "member_removed"

    github_user_id = payload_body.dig("membership", "user", "id")
    github_organization_id = payload_body.dig("organization", "id")
    organizations = Organization.where(github_id: github_organization_id)

    return false if organizations.empty?

    failed_removals = organizations.reject do |org|
      user = org.users.find_by(uid: github_user_id)

      if user
        TransferAssignmentsService.new(org, user).transfer
        org.users.delete(user)
      else
        false
      end
    end

    # This method should only report success (by returning true) if we were able to remove
    # the user from all of the organizations tied to the given github_organization_id
    failed_removals.empty?
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
