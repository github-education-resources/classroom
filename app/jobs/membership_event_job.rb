# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#membershipevent
class MembershipEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body.dig("action") == "removed"

    user_id = payload_body.dig("member", "id")
    team_id = payload_body.dig("team", "id")
    user = User.find_by(uid: user_id)
    group_id = Group.find_by(github_team_id: team_id).id

    repo_accesses = GroupAssignmentRepo.find_by(group_id: group_id).repo_accesses

    repo_access = repo_accesses.find_by(user_id: user.id)
    repo_access.delete if repo_access

    # Do we remove github_repo as well ?
  end
end
