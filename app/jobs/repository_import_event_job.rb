# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#repositoryimportevent
class RepositoryImportEventJob < ApplicationJob
  queue_as :porter_status

  CREATE_COMPLETE = "Your GitHub repository was created."
  IMPORT_FAILED = "We were not able to import starter code to your assignment, please try again."
  IMPORT_CANCELLED = "Your starter code import was manually cancelled, please try again."

  def perform(payload_body)
    github_repo_id = payload_body.dig("repository", "id")
    status = payload_body.dig("status")

    repo = AssignmentRepo.find_by(github_repo_id: github_repo_id)
    repo ||= GroupAssignmentRepo.find_by(github_repo_id: github_repo_id)
    return if repo.blank?

    if repo.is_a?(AssignmentRepo)
      handle_assignment_repo(repo, status)
    else
      handle_group_assignment_repo(repo, status)
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def handle_assignment_repo(assignment_repo, status)
    user = assignment_repo.user
    assignment = assignment_repo.assignment
    invitation = assignment.invitation
    invite_status = invitation.status(user)
    channel = RepositoryCreationStatusChannel.channel(user_id: user.id, assignment_id: assignment_repo.assignment.id)

    case status
    when "success"
      invite_status.completed!
      broadcast_assignment_repo_success(channel, invite_status)
      GitHubClassroom.statsd.increment("v3_exercise_repo.import.success")
    when "failure"
      invite_status.errored_importing_starter_code!
      broadcast_assignment_repo_failure(channel, IMPORT_FAILED, invite_status)
      GitHubClassroom.statsd.increment("v3_exercise_repo.import.failure")
    when "cancelled"
      invite_status.errored_importing_starter_code!
      broadcast_assignment_repo_failure(channel, IMPORT_CANCELLED, invite_status)
      GitHubClassroom.statsd.increment("v3_exercise_repo.import.cancelled")
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable MethodLength
  # rubocop:disable Metrics/AbcSize
  def handle_group_assignment_repo(group_assignment_repo, status)
    group = group_assignment_repo.group
    organization = group_assignment_repo.organization
    assignment = group_assignment_repo.assignment
    invitation = assignment.invitation
    invite_status = invitation.status(group)
    channel = GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: assignment.id)

    return unless organization.feature_enabled?(:group_import_resiliency)

    case status
    when "success"
      invite_status.completed!
      broadcast_assignment_repo_success(channel, invite_status)
      GitHubClassroom.statsd.increment("v3_group_exercise_repo.import.success")
    when "failure"
      invite_status.errored_importing_starter_code!
      broadcast_assignment_repo_failure(channel, IMPORT_FAILED, invite_status)
      GitHubClassroom.statsd.increment("v3_group_exercise_repo.import.failure")
    when "cancelled"
      invite_status.errored_importing_starter_code!
      broadcast_assignment_repo_failure(channel, IMPORT_CANCELLED, invite_status)
      GitHubClassroom.statsd.increment("v3_group_exercise_repo.import.cancelled")
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable Metrics/AbcSize

  def broadcast_assignment_repo_success(channel, invite_status)
    ActionCable.server.broadcast(
      channel,
      text: CREATE_COMPLETE,
      status: invite_status.status,
      status_text: "Done"
    )
  end

  def broadcast_assignment_repo_failure(channel, message, invite_status)
    ActionCable.server.broadcast(
      channel,
      error: message,
      status: invite_status.status,
      status_text: "Failed"
    )
  end
end
