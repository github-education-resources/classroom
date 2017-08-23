# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#repositoryevent
class RepositoryEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body.dig("action") == "deleted"
    github_repo_id = payload_body.dig("repository", "id")

    repo = AssignmentRepo.find_by(github_repo_id: github_repo_id)
    repo ||= GroupAssignmentRepo.find_by(github_repo_id: github_repo_id)

    repo&.destroy!
  end
end
