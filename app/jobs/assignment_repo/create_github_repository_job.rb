# frozen_string_literal: true

class AssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    queue_as :create_repository
    retry_on Creator::Result::Error, wait: :exponentially_longer, queue: :create_repository

    class Status
      CREATE_REPO = "Creating repository"
      ADDING_COLLABORATOR = "Adding collaborator"
      IMPORT_STARTER_CODE = "Importing starter code"
    end

    # Create an AssignmentRepo
    #
    # assignment - The Assignment that will own the AssignmentRepo.
    # user       - The User that the AssignmentRepo will belong to.
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(assignment, user)
      start = Time.zone.now

      creator = Creator.new(assignment: assignment, user: user)

      creator.verify_organization_has_private_repos_available!

      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: Status::CREATE_REPO
      )

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: creator.create_github_repository!,
        user: user
      )

      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: Status::ADDING_COLLABORATOR
      )

      creator.add_user_to_repository!(assignment_repo.github_repo_id)

      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: Status::IMPORT_STARTER_CODE
      )

      creator.push_starter_code!(assignment_repo.github_repo_id) if assignment.starter_code?

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid
        raise Creator::Result::Error, Creator::DEFAULT_ERROR_MESSAGE
      end

      duration_in_millseconds = (Time.zone.now - start) * 1_000
      GitHubClassroom.statsd.timing("exercise_repo.create.time", duration_in_millseconds)

      PorterStatusJob.perform_later(assignment_repo.github_repository, user)
    rescue Creator::Result::Error => err
      creator.delete_github_repository(assignment_repo.try(:github_repo_id))
      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: err
      )
      raise err
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
  end
end
