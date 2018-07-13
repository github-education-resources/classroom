# frozen_string_literal: true

class AssignmentRepo
  class PorterStatusJob < ApplicationJob
    queue_as :porter_status
    retry_on Octopoller::TimeoutError, attempts: 10, queue: :porter_status

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity
    def perform(assignment_repo, user)
      github_repository = assignment_repo.github_repository

      result = Octopoller.poll(timeout: 30) do
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
        assignment_repo.assignment.invitation&.errored!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result,
          status: assignment_repo.assignment.invitation&.status
        )
        logger.warn result.to_s
      when Creator::REPOSITORY_CREATION_COMPLETE
        assignment_repo.assignment.invitation&.completed!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result,
          status: assignment_repo.assignment.invitation&.status
        )
      end
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity
  end
end
