# frozen_string_literal: true

class CreateGitHubRepositoryNewJob < ApplicationJob
  queue_as :create_repository

  def perform(assignment, collaborator, retries: 0)
    return unless assignment.invitation.status(collaborator).waiting?
    service = CreateGitHubRepoService.new(assignment, collaborator)
    result = service.perform
    raise CreateGitHubRepoService::Result::Error, result.error if result.failed?
  rescue CreateGitHubRepoService::Result::Error => error
    handle_error(error, service, retries)
  end

  def handle_error(err, service, retries)
    logger.warn(err.message)
    if retries.positive?
      service.invite_status.waiting!
      CreateGitHubRepositoryNewJob.perform_later(service.assignment, service.collaborator, retries: retries - 1)
    else
      service.invite_status.errored_creating_repo!
      CreateGitHubRepoService::Broadcaster.call(service.entity, err, :error)
    end
  end
end
