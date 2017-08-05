# frozen_string_literal: true

require "concerns/repo_setup.rb"

class RepoSetupJob < ApplicationJob
  queue_as :repo_setup

  def perform(assignment_repo_type, assignment_repo_id)
    @assignment_repo = get_assignment_repo assignment_repo_type, assignment_repo_id

    return unless @assignment_repo

    if @assignment_repo.github_repository.import_progress[:status] != "complete"
      RepoSetupJob.set(wait: 1.hour).perform_later(assignment_repo_type, assignment_repo_id)
    else
      perform_setup(@assignment_repo, classroom_config) unless @assignment_repo.configured?
    end
  end

  private

  def get_assignment_repo(class_name, id)
    return nil unless [AssignmentRepo.name, GroupAssignmentRepo.name].include? class_name
    class_name.constantize.find(id)
  rescue ActiveRecord::ActiveRecordError
    nil
  end

  def classroom_config
    starter_code_repo_id = @assignment_repo.starter_code_repo_id
    client               = @assignment_repo.creator.github_client

    starter_repo         = GitHubRepository.new(client, starter_code_repo_id)
    ClassroomConfig.new(starter_repo)
  end
end
