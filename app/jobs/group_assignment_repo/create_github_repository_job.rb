# frozen_string_literal: true

class GroupAssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"
    CREATE_COMPLETE     = "Your GitHub repository was created."

    queue_as :create_repository

    # Creates a GroupAssignmentRepo and an associated GitHub repo.
    # Starts a source import if starter code is specified.
    #
    # group_assignment - The assignment that will be used to create the GroupAssignmentRepo
    # group            - The group that the GroupAssignmentRepo will belong to
    # retries          - The number of times the job will automatically retry
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(group_assignment, group, retries: 0)
      start = Time.zone.now
      invite_status = group_assignment.invitation.status(group)
      return unless invite_status.waiting?
      invite_status.creating_repo!

      broadcast_message(CREATE_REPO, invite_status, group_assignment, group)

      group_assignment_repo = create_group_assignment_repo(group_assignment, group)
      report_time(start)

      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.success")
      if group_assignment.starter_code?
        invite_status.importing_starter_code!
        broadcast_message(
          IMPORT_STARTER_CODE,
          invite_status,
          group_assignment,
          group,
          group_assignment_repo&.github_repository&.html_url
        )
        GitHubClassroom.statsd.increment("group_exercise_repo.import.started")
      else
        invite_status.completed!
        broadcast_message(CREATE_COMPLETE, invite_status, group_assignment, group)
      end
    rescue Creator::Result::Error => error
      handle_error(error, group_assignment, group, invite_status, retries)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

    private

    # Creates a GroupAssignmentRepo with an associated GitHub repo
    # If creation fails, it deletes the GitHub repo
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def create_group_assignment_repo(group_assignment, group)
      creator = Creator.new(group_assignment: group_assignment, group: group)
      creator.verify_organization_has_private_repos_available!

      github_repository = creator.create_github_repository!

      group_assignment_repo = group_assignment.group_assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        group: group
      )
      creator.add_team_to_github_repository!(group_assignment_repo.github_repo_id)
      creator.push_starter_code!(group_assignment_repo.github_repo_id) if group_assignment.starter_code?
      group_assignment_repo.save!
      group_assignment_repo
    rescue ActiveRecord::RecordInvalid => error
      creator.delete_github_repository(group_assignment_repo&.github_repo_id)
      logger.warn(error.message)
      raise Creator::Result::Error, Creator::DEFAULT_ERROR_MESSAGE
    rescue Creator::Result::Error => error
      creator.delete_github_repository(group_assignment_repo&.github_repo_id)
      raise error
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

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
        report_error
      end
      logger.warn(error.message)
    end

    # Broadcasts a ActionCable message with a status to the given group_assignment and group
    #
    def broadcast_message(message, invite_status, group_assignment, group, repo_url = nil)
      ActionCable.server.broadcast(
        GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
        text: message,
        status: invite_status.status,
        repo_url: repo_url
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
