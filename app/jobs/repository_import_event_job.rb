# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#repositoryimportevent
class RepositoryImportEventJob < ApplicationJob
  queue_as :porter_status

  CREATE_COMPLETE = "Your GitHub repository was created."
  IMPORT_FAILED = "We were not able to import starter code to your assignment, please try again."

  def perform(payload_body)
    github_repo_id = payload_body.dig("repository", "id")
    status = payload_body.dig("status")
    html_url = payload_body.dig("repository", "html_url")

    repo = AssignmentRepo.find_by(github_repo_id: github_repo_id)
    return if repo.blank?
    # Group assignments coming in a follow up PR
    # repo ||= GroupAssignmentRepo.find_by(github_repo_id: github_repo_id)

    handle_assignment_repo(repo, status, html_url)
  end

  private

  # rubocop:disable MethodLength
  def handle_assignment_repo(assignment_repo, status, html_url)
    user = assignment_repo.user
    invitation = assignment_repo.assignment.invitation
    invite_status = invitation.status(user)

    return unless user.feature_enabled?(:repository_import_webhook)

    case status
    when "success"
      invite_status.completed!
      broadcast_assignment_repo_success(user, invite_status, html_url)
      GitHubClassroom.statsd.increment("v3_exercise_repo.import.success")
    when "failure"
      invite_status.errored_importing_starter_code!
      broadcast_assignment_repo_failure(user, invite_status, html_url)
      GitHubClassroom.statsd.increment("v3_exercise_repo.import.failure")
    end
  end
  # rubocop:enable MethodLength

  def broadcast_assignment_repo_success(user, invite_status, html_url)
    ActionCable.server.broadcast(
      RepositoryCreationStatusChannel.channel(user_id: user.id),
      text: CREATE_COMPLETE,
      status: invite_status.status,
      percent: 100,
      status_text: "Done",
      repo_url: html_url
    )
  end

  def broadcast_assignment_repo_failure(user, invite_status, html_url)
    ActionCable.server.broadcast(
      RepositoryCreationStatusChannel.channel(user_id: user.id),
      error: IMPORT_FAILED,
      status: invite_status.status,
      percent: nil,
      status_text: "Failed",
      repo_url: html_url
    )
  end
end
