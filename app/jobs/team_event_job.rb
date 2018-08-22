# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#teamevent
class TeamEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body["action"] == "deleted"

    team_id = payload_body.dig("team", "id")
    group = Group.find_by(github_team_id: team_id)

    return true if group.blank?

    group.destroy
  end
end
