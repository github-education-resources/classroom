# frozen_string_literal: true
class Assignment
  class RepositoryVisibilityJob < ApplicationJob
    queue_as :assignment

    def perform(assignment, change:)
      assignment.repos.each do |assignment_repo|
        assignment_repo.github_repository.public = change.last
      end
    end
  end
end
