# frozen_string_literal: true

class AssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"

    queue_as :create_repository
    retry_on Creator::Result::Error, wait: :exponentially_longer, queue: :create_repository

    # Create an AssignmentRepo
    #
    # assignment - The Assignment that will own the AssignmentRepo.
    # user       - The User that the AssignmentRepo will belong to.
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(assignment, user)
      start = Time.zone.now

      return unless assignment.invitation&.waiting? \
        || assignment.invitation&.errored_creating_repo? \
        || assignment.invitation.status.nil?

      assignment.invitation&.creating_repo!

      creator = Creator.new(assignment: assignment, user: user)

      creator.verify_organization_has_private_repos_available!

      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: CREATE_REPO,
        status: assignment.invitation&.status
      )

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: creator.create_github_repository!,
        user: user
      )

      creator.add_user_to_repository!(assignment_repo.github_repo_id)

      creator.push_starter_code!(assignment_repo.github_repo_id) if assignment.starter_code?

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid
        raise Creator::Result::Error, Creator::DEFAULT_ERROR_MESSAGE
      end

      duration_in_millseconds = (Time.zone.now - start) * 1_000
      GitHubClassroom.statsd.timing("v2_exercise_repo.create.time", duration_in_millseconds)
      GitHubClassroom.statsd.increment("v2_exercise_repo.create.success")

      if assignment.starter_code?
        assignment.invitation&.importing_starter_code!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: IMPORT_STARTER_CODE,
          status: assignment.invitation&.status
        )
        PorterStatusJob.perform_later(assignment_repo, user)
      else
        assignment.invitation&.completed!
        ActionCable.server.broadcast(
          RepositoryCreationStatusChannel.channel(user_id: user.id),
          text: Creator::REPOSITORY_CREATION_COMPLETE,
          status: assignment.invitation&.status
        )
      end
    rescue Creator::Result::Error => err
      creator.delete_github_repository(assignment_repo.try(:github_repo_id))
      assignment.invitation&.errored_creating_repo!
      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id),
        text: err,
        status: assignment.invitation&.status
      )
      GitHubClassroom.statsd.increment("v2_exercise_repo.create.fail")
      raise err
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
  end
end
