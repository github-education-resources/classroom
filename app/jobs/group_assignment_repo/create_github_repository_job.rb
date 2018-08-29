# frozen_string_literal: true

class GroupAssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"
    CREATE_COMPLETE     = "Your GitHub repository was created."

    queue_as :create_repository

    # Create an GroupAssignmentRepo
    #
    # group_assignment - The Assignment that will own the GroupAssignmentRepo
    # group       - The User that the GroupAssignmentRepo will belong to
    # retries    - The number of times the job will automatically retry
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(group_assignment, group, retries: 0)
      start = Time.zone.now
      invite_status = group_assignment.invitation.status(group)
      return unless invite_status.waiting?
      invite_status.creating_repo!

      broadcast_message(CREATE_REPO, invite_status, group_assignment, group)

      # TODO: Implement PorterStatusJob (follow up PR)
      # group_assignment_repo = GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
      GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
      report_time(start)

      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.success")
      if group_assignment.starter_code?
        invite_status.importing_starter_code!
        broadcast_message(IMPORT_STARTER_CODE, invite_status, group_assignment, group)
        # TODO: Implement PorterStatusJob (follow up PR)
        # PorterStatusJob.perform_later(group_assignment_repo, group) create new PorterStatusJob for groups
      else
        invite_status.completed!
        broadcast_message(CREATE_COMPLETE, invite_status, group_assignment, group)
      end
    rescue GitHub::Error, ActiveRecord::RecordInvalid => error
      handle_error(error, group_assignment, group, invite_status, retries)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity
    # rubocop:enable PerceivedComplexity

    private

    # Given an error, retries the job if the number of retries left is positive
    # or broadcasts a failure to the group
    #
    def handle_error(error, group_assignment, group, invite_status, retries)
      if retries.positive?
        invite_status.waiting!
        CreateGitHubRepositoryJob.perform_later(group_assignment, group, retries: retries - 1)
      else
        invite_status.errored_creating_repo!
        broadcast_error(error, invite_status, group_assignment, group)
        report_error(error)
      end
      logger.warn(error.message)
    end

    # Broadcasts a ActionCable message with a status to the given group_assignment and group
    #
    def broadcast_message(message, invite_status, group_assignment, group)
      ActionCable.server.broadcast(
        GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
        text: message,
        status: invite_status.status
      )
    end

    # Broadcasts a ActionCable error with a status to the given group_assignment and group
    #
    def broadcast_error(error, invite_status, group_assignment, group)
      ActionCable.server.broadcast(
        GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
        error: error,
        status: invite_status.status
      )
    end

    # Reports the elapsed time to Datadog
    #
    def report_time(start_time)
      duration_in_millseconds = (Time.zone.now - start_time) * 1_000
      GitHubClassroom.statsd.timing("v2_group_exercise_repo.create.time", duration_in_millseconds)
    end

    # Maps the type of error to a Datadog error
    #
    def report_error
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.fail")
    end
  end
end
