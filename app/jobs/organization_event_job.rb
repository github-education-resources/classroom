# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#organizationevent
class OrganizationEventJob < ApplicationJob
  queue_as :github_event

  # rubocop:disable Metrics/AbcSize
  def perform(payload_body)
    return true unless payload_body.dig("action") == "member_removed"

    github_user_id = payload_body.dig("membership", "user", "id")
    github_organization_id = payload_body.dig("organization", "id")
    @organization = Organization.find_by(github_id: github_organization_id)

    return false if @organization.blank?
    return false if @organization.users.count == 1

    @user = @organization.users.find_by(uid: github_user_id)

    return true unless @user
    TransferAssignmentsService.new(@organization, @user).transfer
    @organization.users.delete(@user)
  end
  # rubocop:enable Metrics/AbcSize
end
