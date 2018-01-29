# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#membershipevent
class MembershipEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body.dig("action") == "removed"

    user_id = payload_body.dig("member", "id")
    team_id = payload_body.dig("team", "id")

    user = User.find_by(uid: user_id)
    return true unless user.present?

    group = Group.find_by(github_team_id: team_id)
    return true unless group.present?

    group.repo_accesses.find_by(user_id: user.id)
    repo_access&.destroy
  end
end
