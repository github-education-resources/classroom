# frozen_string_literal: true

class AssignmentRepo
  class PorterStatusJob < ApplicationJob
    class ImportInProgress < StandardError; end
    queue_as :porter_status
    retry_on Octopoller::TimeoutError, queue: :porter_status

    def perform(assignment_repo, user)
      github_repository = assignment_repo.github_repository

      result = Octopoller.poll do # TODO log errors
        begin
          progress = github_repository.import_progress[:status]
          case progress
          when *GitHubRepository::IMPORT_ONGOING
            raise ImportInProgress, Creator::IMPORT_ONGOING
          when GitHubRepository::IMPORT_COMPLETE
            Creator::REPOSITORY_CREATION_COMPLETE
          end
        rescue GitHub::Error
          Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
        end
      end

      case result
      when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result
        )
      when Creator::REPOSITORY_CREATION_COMPLETE
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result
        )
      end
    end
  end
end
