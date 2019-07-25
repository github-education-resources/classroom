# frozen_string_literal: true

class GroupAssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    queue_as :create_repository

    # Creates a GroupAssignmentRepo and an associated GitHub repo.
    # Starts a source import if starter code is specified.
    #
    # group_assignment - The assignment that will be used to create the GroupAssignmentRepo
    # group            - The group that the GroupAssignmentRepo will belong to
    # retries          - The number of times the job will automatically retry
    #
    def perform(group_assignment, group, retries: 0)
      invite_status = group_assignment.invitation.status(group)
      return unless invite_status.waiting?
      creator = Creator.new(group_assignment: group_assignment, group: group)
      result = creator.perform
      raise Creator::Result::Error, result.error if result.failed?
    rescue Creator::Result::Error => error
      handle_error(error, creator, retries)
    end

    private

    # Given an error, retries the job if the number of retries left is positive
    # or broadcasts a failure to the group
    #
    # rubocop:disable AbcSize
    def handle_error(error, creator, retries)
      if retries.positive?
        creator.invite_status.waiting!
        CreateGitHubRepositoryJob.perform_later(creator.group_assignment, creator.group, retries: retries - 1)
      else
        creator.invite_status.errored_creating_repo!
        creator.broadcast_error(error)
        GitHubClassroom.statsd.increment("group_exercise_repo.create.fail")
      end
      logger.warn(error.message)
    end
    # rubocop:enable AbcSize
  end
end
