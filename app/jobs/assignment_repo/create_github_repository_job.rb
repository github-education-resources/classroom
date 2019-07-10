# frozen_string_literal: true

class AssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating GitHub repository."
    IMPORT_STARTER_CODE = "Importing starter code."

    queue_as :create_repository

    # Create an AssignmentRepo
    #
    # assignment - The Assignment that will own the AssignmentRepo
    # user       - The User that the AssignmentRepo will belong to
    # retries    - The number of times the job will automatically retry
    #
    def perform(assignment, user, retries: 0)
      invite_status = assignment.invitation.status(user)
      return unless invite_status.waiting?
      creator = Creator.new(assignment: assignment, user: user)
      result = creator.perform
      raise Creator::Result::Error, result.error if result.failed?
    rescue Creator::Result::Error => error
      handle_error(error, creator, retries)
    end

    private

    # Given an error, retries the job if retries are positive
    # or broadcasts a failure to the user
    #
    # rubocop:disable MethodLength
    def handle_error(err, creator, retries)
      logger.warn(err.message)
      if retries.positive?
        creator.invite_status.waiting!
        CreateGitHubRepositoryJob.perform_later(creator.assignment, creator.user, retries: retries - 1)
      else
        creator.invite_status.errored_creating_repo!
        creator.broadcast_message(
          type: :error,
          message: err,
          status_text: "Failed"
        )
        creator.report_error(err)
      end
    end
    # rubocop:enable MethodLength
  end
end
