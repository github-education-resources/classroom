# frozen_string_literal: true

class CreateGitHubRepositoryNewJob < ApplicationJob
  queue_as :create_repository

  # Creates an AssignmentRepo or a GroupAssignmentRepo
  #
  # assignment   - The Assignment that will own the AssignmentRepo /
  #                The GroupAssignment that will own the GroupAssignmentRepo
  # collaborator - The User that the AssignmentRepo will belong to /
  #                The Group that the GroupAssignmentRepo will belong to
  # retries    - The number of times the job will automatically retry
  #
  def perform(assignment, collaborator, retries: 0)
    return unless assignment.invitation.status(collaborator).waiting?
    service = CreateGitHubRepoService.new(assignment, collaborator)
    result = service.perform
    raise CreateGitHubRepoService::Result::Error, result.error if result.failed?
  rescue CreateGitHubRepoService::Result::Error => error
    handle_error(error.message, service, retries)
  end

  private

  # Given an error, retries the job if retries are positive
  # or broadcasts a failure to the user
  #
  def handle_error(err, service, retries)
    logger.warn(err)
    if retries.positive?
      service.invite_status.waiting!
      CreateGitHubRepositoryNewJob.perform_later(service.assignment, service.collaborator, retries: retries - 1)
    else
      service.invite_status.errored_creating_repo!
      CreateGitHubRepoService::Broadcaster.call(service.entity, err, :error)
    end
  end
end
