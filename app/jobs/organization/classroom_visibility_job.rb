# frozen_string_literal: true

class Organization
  class ClassroomVisibilityJob < ApplicationJob
    queue_as :classroom_visibility

    # rubocop:disable SkipsModelValidations
    def perform(organization, visibility)
      public_classroom = (visibility == "public" ? true : false)
      assignments = organization.assignments + organization.group_assignments
      assignments.each do |assignment|
        assignment.update_attribute("public_repo", public_classroom)
        change_visibility_in_all_assignment_repos(assignment, public_classroom)
      end
    end

    private

    def change_visibility_in_all_assignment_repos(assignment, public_repo)
      assignment.repos.each do |assignment_repo|
        begin
          assignment_repo.github_repository.public = public_repo
        rescue Octokit::InvalidRepository, GitHub::NotFound, GitHub::Forbidden, GitHub::Error
          next
        end
      end
    end
  end
end
