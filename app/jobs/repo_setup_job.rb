# frozen_string_literal: true

require "concerns/repo_setup.rb"

class RepoSetupJob < ApplicationJob
  queue_as :repo_setup

  rescue_from ActiveJob::DeserializationError do |e|
    logger.error(e)
  end

  def perform(assignment_repo)
    if assignment_repo.github_repository.importing?
      RepoSetupJob.set(wait: 1.hour).perform_later(assignment_repo)
    else
      perform_setup(assignment_repo, classroom_config(assignment_repo)) unless assignment_repo.configured?
    end
  end

  private

  def classroom_config(assignment_repo)
    starter_code_repo_id = assignment_repo.starter_code_repo_id
    client               = assignment_repo.creator.github_client

    starter_repo         = GitHubRepository.new(client, starter_code_repo_id)
    ClassroomConfig.new(starter_repo)
  end
end
