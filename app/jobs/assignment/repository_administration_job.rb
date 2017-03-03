# frozen_string_literal: true
module Assignment
  class RepositoryAdministrationJob < ApplicationJob
    queue :assignment

    def perform(assignment, time:, change:)
      assignment.assignment_repos.each do |assignment_repo|
        assignment_repo.github_repository.private = change
      end
    end
  end
end
