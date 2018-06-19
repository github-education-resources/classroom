# frozen_string_literal: true

class AssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    queue_as :create_repository
    retry_on Creator::Result::Error, queue: :create_repository

    # Create an AssignmentRepo.
    #
    # assignment - The Assignment that will own the AssignmentRepo.
    # user       - The User that the AssignmentRepo will belong to.
    # rubocop:disable MethodLength
    def perform(assignment, user)
      creator = Creator.new(assignment: assignment, user: user)

      creator.verify_organization_has_private_repos_available!

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: creator.create_github_repository!,
        user: user
      )

      creator.add_user_to_repository!(assignment_repo.github_repo_id)

      if assignment.starter_code?
        creator.push_starter_code!(assignment_repo.github_repo_id)
      end

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid
        raise Creator::Result::Error, Creator::DEFAULT_ERROR_MESSAGE
      end

      # on success kick off porter polling cascading job
    rescue Creator::Result::Error => err
      creator.delete_github_repository(assignment_repo.try(:github_repo_id))
      raise err
    end
    # rubocop:enable MethodLength
  end
end
