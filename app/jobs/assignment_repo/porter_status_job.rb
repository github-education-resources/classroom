# frozen_string_literal: true

class AssignmentRepo
  class PorterStatusJob < ApplicationJob
    class ImportInProgress < StandardError; end
    queue_as :porter_status
    retry_on Octopoller::TimeoutError, queue: :porter_status

    def perform(github_repository, user)

      result = Octopoller.poll do # TODO log errors
        case github_repository.import_progress[:status]
        when *GitHubRepository::IMPORT_ONGOING
          raise ImportInProgress, Creator::IMPORT_ONGOING
        when *GitHubRepository::IMPORT_ERRORS
          return Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
        when GitHubRepository::IMPORT_COMPLETE
          return Creator::REPOSITORY_CREATION_COMPLETE
        end
      end

      case result
      when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
        # broadcast that the user should retry
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result
        )
      when Creator::REPOSITORY_CREATION_COMPLETE
        # broadcast good vibes
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: result
        )
      end
    end
  end
end
