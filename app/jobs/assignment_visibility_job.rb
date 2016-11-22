# frozen_string_literal: true
class AssignmentVisibilityJob < ApplicationJob
  queue_as :assignment_visibility

  def perform(assignment)
    assignment.repos.each do |repo|
      repo.github_repository.private = assignment.private?
    end
  end
end
