# frozen_string_literal: true

class GroupAssignmentRepo
  class PorterStatusJob < ApplicationJob
    REPO_IMPORT_STEPS = GitHubRepository::IMPORT_STEPS
    queue_as :porter_status

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity

    # def perform(assignment_repo, user)
    #   github_repository = assignment_repo.github_repository

    #   invite_status = assignment_repo.assignment.invitation.status(user)

    #   begin
    #     last_progress = nil
    #     result = Octopoller.poll(timeout: 30.seconds) do
    #       begin
    #         progress = github_repository.import_progress
    #         case progress[:status]
    #         when GitHubRepository::IMPORT_COMPLETE
    #           Creator::REPOSITORY_CREATION_COMPLETE
    #         when *GitHubRepository::IMPORT_ERRORS
    #           Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
    #         when *GitHubRepository::IMPORT_ONGOING
    #           if last_progress != progress[:status]
    #             ActionCable.server.broadcast(
    #               RepositoryCreationStatusChannel.channel(user_id: user.id),
    #               status: invite_status.status,
    #               text: AssignmentRepo::Creator::IMPORT_ONGOING,
    #               percent: ((REPO_IMPORT_STEPS.index(progress[:status]) + 1) * 100) / REPO_IMPORT_STEPS.count,
    #               status_text: progress[:status_text],
    #               repo_url: github_repository.html_url
    #             )
    #             last_progress = progress[:status]
    #           end
    #           :re_poll
    #         end
    #       rescue GitHub::Error => error
    #         logger.warn error.to_s
    #         Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
    #       end
    #     end

    #     case result
    #     when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
    #       invite_status.errored_importing_starter_code!
    #       ActionCable.server.broadcast(
    #         RepositoryCreationStatusChannel.channel(user_id: user.id),
    #         error: result,
    #         status: invite_status.status
    #       )
    #       logger.warn result.to_s
    #       GitHubClassroom.statsd.increment("v2_exercise_repo.import.fail")
    #       assignment_repo.destroy
    #     when Creator::REPOSITORY_CREATION_COMPLETE
    #       invite_status.completed!
    #       ActionCable.server.broadcast(
    #         RepositoryCreationStatusChannel.channel(user_id: user.id),
    #         text: result,
    #         status: invite_status.status,
    #         percent: 100,
    #         status_text: "Done",
    #         repo_url: github_repository.html_url
    #       )
    #       GitHubClassroom.statsd.increment("v2_exercise_repo.import.success")
    #     end
    #   rescue Octopoller::TimeoutError
    #     GitHubClassroom.statsd.increment("v2_exercise_repo.import.timeout")
    #     PorterStatusJob.perform_later(assignment_repo, user)
    #   end
    # end

    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity

    private

    # Broadcasts an ActionCable message
    # group_assignment    - the GroupAssignment that was used to create the GroupAssignmentRepo
    # group               - the group to broadcast the message to
    # text                - a human readable message
    # group_invite_status - the GroupInviteStatus model to read status from
    # percent             - the percent of the repo import that has been imported
    # status_text         - a human readable phrase about the current state of the import
    # repo_url            - the GitHub repository url
    #
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

    # Broadcasts an ActionCable error
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
