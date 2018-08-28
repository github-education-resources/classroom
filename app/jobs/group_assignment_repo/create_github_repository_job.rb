# frozen_string_literal: true

class GroupAssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"

    queue_as :create_repository

    # Create an GroupAssignmentRepo
    #
    # group_assignment - The Assignment that will own the GroupAssignmentRepo
    # group       - The User that the GroupAssignmentRepo will belong to
    # retries    - The number of times the job will automatically retry
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity
    # rubocop:disable PerceivedComplexity
    def perform(group_assignment, group, retries: 0)
      start = Time.zone.now
      invite_status = group_assignment.invitation.status(user)
      return unless invite_status.waiting?
      invite_status.creating_repo!

      broadcast_message(CREATE_REPO, invite_status, group_assignment, group)

      group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
      report_time

      GitHubClassroom.statsd.increment("v2_exercise_repo.create.success")

      if assignment.starter_code?
        invite_status.importing_starter_code!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: IMPORT_STARTER_CODE,
          status: invite_status.status
        )
        PorterStatusJob.perform_later(assignment_repo, user)
      else
        invite_status.completed!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: Creator::REPOSITORY_CREATION_COMPLETE,
          status: invite_status.status
        )
      end
    rescue GitHub::Error, ActiveRecord::RecordInvalid => err

    end

    private

    # Broadcasts a ActionCable message with a status to the given assignment and group
    #
    def broadcast_message(message, invite_status, assignment, group)
     ActionCable.server.broadcast(
       GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: assignment.id),
       text: message,
       status: invite_status.status
     )
    end

    # Reports the elapsed time to Datadog
    #
    def report_time(start_time)
     duration_in_millseconds = (Time.zone.now - start_time) * 1_000
     GitHubClassroom.statsd.timing("v2_exercise_repo.create.time", duration_in_millseconds)
    end
  end
end
