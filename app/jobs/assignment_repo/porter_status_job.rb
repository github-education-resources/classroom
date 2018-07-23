# frozen_string_literal: true

class AssignmentRepo
  class PorterStatusJob < ApplicationJob
    queue_as :porter_status

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity
    def perform(assignment_repo, user)
      github_repository = assignment_repo.github_repository

      invite_status = assignment_repo.assignment.invitation&.status(user)

      begin
        result = Octopoller.poll(timeout: 30.seconds) do
          begin
            progress = github_repository.import_progress[:status]
            case progress
            when GitHubRepository::IMPORT_COMPLETE
              Creator::REPOSITORY_CREATION_COMPLETE
            when *GitHubRepository::IMPORT_ERRORS
              Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
            when *GitHubRepository::IMPORT_ONGOING
              logger.info AssignmentRepo::Creator::IMPORT_ONGOING
              :re_poll
            end
          rescue GitHub::Error => error
            logger.warn error.to_s
            Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
          end
        end

        case result
        when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
          invite_status&.errored_importing_starter_code!
          ActionCable.server.broadcast(
            RepositoryCreationStatusChannel.channel(user_id: user.id),
            text: result,
            status: invite_status&.status
          )
          logger.warn result.to_s
          GitHubClassroom.statsd.increment("v2_exercise_repo.import.fail")
          assignment_repo.destroy
        when Creator::REPOSITORY_CREATION_COMPLETE
          invite_status&.completed!
          ActionCable.server.broadcast(
            RepositoryCreationStatusChannel.channel(user_id: user.id),
            text: result,
            status: invite_status&.status
          )
          GitHubClassroom.statsd.increment("v2_exercise_repo.import.success")
        end
      rescue Octopoller::TimeoutError
        GitHubClassroom.statsd.increment("v2_exercise_repo.import.timeout")
        PorterStatusJob.perform_later(assignment_repo, user)
      end
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity
  end
end
