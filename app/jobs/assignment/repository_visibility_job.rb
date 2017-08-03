# frozen_string_literal: true

class Assignment
  class RepositoryVisibilityJob < ApplicationJob
    queue_as :assignment

    rescue_from ActiveJob::DeserializationError do |_exception|
      # Assignment no longer exists. No point in running this job anymore.
      # Just swallow the error so we don't retry
    end

    def perform(assignment, change:)
      assignment.repos.each do |assignment_repo|
        assignment_repo.github_repository.public = change.last
      end
    end
  end
end
