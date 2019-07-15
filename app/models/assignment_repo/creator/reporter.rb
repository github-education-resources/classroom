# frozen_string_literal: true

class AssignmentRepo
  class Creator
    # This class reports messages to our metrics system and,
    # also broadcasts messages to our channels for progress updates
    #
    class Reporter
      attr_reader :creator
      delegate :user, :assignment, :invite_status, to: :creator

      def initialize(creator)
        @creator = creator
      end

      # Broadcasts a ActionCable message with a status to the given user
      #
      # rubocop:disable MethodLength
      def broadcast_message(type: :text, message:, status_text:, repo_url: nil)
        raise ArgumentError unless %i[text error].include?(type)
        broadcast_args = {
          status: invite_status.status,
          status_text: status_text,
          repo_url: repo_url
        }
        broadcast_args[type] = message
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id, assignment_id: assignment.id),
          broadcast_args
        )
      end
      # rubocop:enable ParameterLists
      # rubocop:enable MethodLength

      # Reports the elapsed time to Datadog
      #
      def report_time(start_time, assignment)
        duration_in_millseconds = (Time.zone.now - start_time) * 1_000
        if assignment.starter_code?
          GitHubClassroom.statsd.timing("exercise_repo.create.time.with_importer", duration_in_millseconds)
        else
          GitHubClassroom.statsd.timing("v2_exercise_repo.create.time", duration_in_millseconds)
          GitHubClassroom.statsd.timing("exercise_repo.create.time", duration_in_millseconds)
        end
      end

      # Maps the type of error to a Datadog error
      #
      # rubocop:disable MethodLength
      # rubocop:disable AbcSize
      def report_error(err)
        case err.message
        when /^#{REPOSITORY_CREATION_FAILED}/
          GitHubClassroom.statsd.increment("v2_exercise_repo.create.repo.fail")
          GitHubClassroom.statsd.increment("exercise_repo.create.repo.fail")
        when /^#{REPOSITORY_COLLABORATOR_ADDITION_FAILED}/
          GitHubClassroom.statsd.increment("v2_exercise_repo.create.adding_collaborator.fail")
          GitHubClassroom.statsd.increment("exercise_repo.create.adding_collaborator.fail")
        when /^#{REPOSITORY_STARTER_CODE_IMPORT_FAILED}/
          GitHubClassroom.statsd.increment("v2_exercise_repo.create.importing_starter_code.fail")
          GitHubClassroom.statsd.increment("exercise_repo.create.importing_starter_code.fail")
        else
          GitHubClassroom.statsd.increment("v2_exercise_repo.create.fail")
          GitHubClassroom.statsd.increment("exercise_repo.create.fail")
        end
      end
      # rubocop:enable MethodLength
      # rubocop:enable AbcSize
    end
  end
end
