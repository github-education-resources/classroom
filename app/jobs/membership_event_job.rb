# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#membershipevent
class MembershipEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body["action"] == "removed"

    user_id = payload_body.dig("member", "id")
    team_id = payload_body.dig("team", "id")

    user = User.find_by(uid: user_id)
    group = Group.find_by(github_team_id: team_id)

    return true unless group.present? && user.present?

    repo_access = group.repo_accesses.find_by(user_id: user.id)
    group.repo_accesses.delete(repo_access)
  end
end
