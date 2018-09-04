# frozen_string_literal: true

class GroupAssignmentRepo
  class PorterStatusJob < ApplicationJob
    queue_as :porter_status

    REPO_IMPORT_STEPS   = GitHubRepository::IMPORT_STEPS
    IMPORT_COMPLETE     = GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_COMPLETE
    IMPORT_ONGOING      = "Your GitHub repository is importing starter code."
    IMPORT_FAILED       = "We were not able to import you the starter code to your assignment, please try again."
    IMPORT_STEP_UNKNOWN = <<~IMPORT_STEP_UNKNOWN
      The source import encountered an unknown step.
      Please make an issue on <a href=\"https://github.com/education/classroom/issues/new/choose\">GitHub Classroom</a>.
    IMPORT_STEP_UNKNOWN

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(group_assignment_repo, group)
      github_repository = group_assignment_repo.github_repository
      group_assignment = group_assignment_repo.group_assignment
      group_invite_status = group_assignment_repo
        .group_assignment
        .group_assignment_invitation
        .status(group)
      poll_import_status(github_repository, group_assignment, group, group_invite_status)

      group_invite_status.completed!
      broadcast_message(
        group_assignment,
        group,
        text: IMPORT_COMPLETE,
        invite_status: group_invite_status,
        percent: step_progress("complete"),
        status_text: "Done",
        repo_url: github_repository.html_url
      )
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.import.success")
    rescue GitHub::Error => error
      group_invite_status.errored_importing_starter_code!
      broadcast_error(group_assignment, group, error: error.message, invite_status: group_invite_status)
      logger.warn error
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.import.fail")
      group_assignment_repo.destroy
    rescue Octopoller::TimeoutError
      GitHubClassroom.statsd.increment("v2_group_exercise_repo.import.timeout")
      PorterStatusJob.perform_later(group_assignment_repo, group)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

    private

    # Polls GitHub's source import's API until the source import completes, fails, or if Octopoller times out
    # On failure -> raises GitHub:Error
    # On timeout -> raises Octopoller::TimeoutError
    # On success -> returns success
    #
    # rubocop:disable MethodLength
    def poll_import_status(github_repository, group_assignment, group, group_invite_status)
      last_progress = nil
      Octopoller.poll(timeout: 30.seconds) do
        progress = github_repository.import_progress
        handle_progress_status(progress[:status]) do
          if last_progress != progress[:status]
            broadcast_message(
              group_assignment,
              group,
              text: IMPORT_ONGOING,
              invite_status: group_invite_status,
              percent: step_progress(progress[:status]),
              status_text: progress[:status_text],
              repo_url: github_repository.html_url
            )
            last_progress = progress[:status]
          end
        end
      end
    end
    # rubocop:enable MethodLength

    # Handles the import progress based on it's status field
    # If the status is an importing status -> yeild and :re_poll
    # If the status is "complete"          -> return IMPORT_COMPLETE
    # If the status is an error            -> raise a GitHub::Error
    # If the status is unknown             -> raise a GitHub::Error
    #
    # status - the status field from a source import status request
    #
    # rubocop:disable MethodLength
    def handle_progress_status(status)
      case status
      when GitHubRepository::IMPORT_COMPLETE
        IMPORT_COMPLETE
      when *GitHubRepository::IMPORT_ERRORS
        raise GitHub::Error, IMPORT_FAILED
      when *GitHubRepository::IMPORT_ONGOING
        yield if block_given?
        :re_poll
      else
        raise GitHub::Error, IMPORT_STEP_UNKNOWN
      end
    end
    # rubocop:enable MethodLength

    # Broadcasts an ActionCable message
    #
    # group_assignment    - the GroupAssignment that was used to create the GroupAssignmentRepo
    # group               - the group to broadcast the message to
    # text                - a human readable message
    # group_invite_status - the GroupInviteStatus model to read status from
    # percent             - the percent of the repo import that has been imported
    # status_text         - a human readable phrase about the current state of the import
    # repo_url            - the GitHub repository url
    #
    # rubocop:disable ParameterLists
    def broadcast_message(group_assignment, group, text:, invite_status:, percent:, status_text:, repo_url:)
      ActionCable.server.broadcast(
        GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
        text: text,
        status: invite_status.status,
        percent: percent,
        status_text: status_text,
        repo_url: repo_url
      )
    end
    # rubocop:enable ParameterLists

    # Broadcasts an ActionCable error
    #
    # group_assignment    - the GroupAssignment that was used to create the GroupAssignmentRepo
    # group               - the group to broadcast the error to
    # error               - a human readable error message
    # group_invite_status - the GroupInviteStatus model to read status from
    #
    def broadcast_error(group_assignment, group, error:, invite_status:)
      ActionCable.server.broadcast(
        GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
        error: error,
        status: invite_status.status,
        status_text: "Errored"
      )
    end

    # Returns an integer value representing the progress of the import
    # 0   -> incomplete
    # 100 -> complete
    #
    # progress_status - the step that the imort is in (in words)
    #
    def step_progress(progress_status)
      ((REPO_IMPORT_STEPS.index(progress_status) + 1) * 100) / REPO_IMPORT_STEPS.count
    end
  end
end
