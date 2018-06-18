# frozen_string_literal: true

# Should this class be namespaced inside AssignmentRepo?
class CreateGitHubRepositoryJob < ActiveJob
  queue_as :repository_create

  # Create an AssignmentRepo.
  #
  # assignment - The Assignment that will own the AssignmentRepo.
  # user       - The User that the AssignmentRepo will belong to.
  def perform(assignment, user)

    creator = AssignmentRepo::Creator.new(assignment: assignment, user: user)

    creator.verify_organization_has_private_repos_available!

    assignment_repo = assignment.assignment_repos.build(
      github_repo_id: creator.create_github_repository!,
      user: user
    )

    creator.add_user_to_repository!(assignment_repo.github_repo_id)

    # on success kick off next cascading job

  rescue Result::Error => err
    creator.delete_github_repository(assignment_repo.try(:github_repo_id))
    AssignmentRepo::Creator.failed(err.message)
  end
end
