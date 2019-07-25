# frozen_string_literal: true

class Organization
  class ClassroomVisibilityJob < ApplicationJob
    queue_as :classroom_visibility

    def perform(organization, visibility)
      public_classroom = (visibility == "public" ? true : false)
      assignments = organization.assignments + organization.group_assignments
      assignments.each do |assignment|
        assignment.update_attribute("public_repo", public_classroom)
        assignment.repos.each do |assignment_repo|
          begin
            assignment_repo.github_repository.public = public_classroom
          rescue Octokit::InvalidRepository, GitHub::NotFound, GitHub::Forbidden, GitHub::Error
            next
          end
        end
      end
    end
  end
end
