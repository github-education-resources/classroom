# frozen_string_literal: true

class GroupAssignmentRepo
  class Creator
    # This class reports messages to our metrics system and,
    # also broadcasts messages to our channels for progress updates
    #
    class Reporter
      attr_reader :creator
      delegate :group, :group_assignment, :invite_status, to: :creator

      def initialize(creator)
        @creator = creator
      end

      # Broadcasts a ActionCable message with a status to the given group_assignment and group
      #
      def broadcast_message(message, repo_url = nil)
        ActionCable.server.broadcast(
          GroupRepositoryCreationStatusChannel.channel(group_id: group.id, group_assignment_id: group_assignment.id),
          text: message,
          status: invite_status.status,
          repo_url: repo_url
        )
      end

      # Broadcasts a ActionCable error with a status to the given group_assignment and group
      #
      def broadcast_error(error)
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
        GitHubClassroom.statsd.timing("group_exercise_repo.create.time", duration_in_millseconds)
      end
    end
  end
end
