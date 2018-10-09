# frozen_string_literal: true

class AssignmentRepo
  class CreateGitHubRepositoryJob < ApplicationJob
    CREATE_REPO         = "Creating GitHub repository."
    IMPORT_STARTER_CODE = "Importing starter code."

    queue_as :create_repository

    # Create an AssignmentRepo
    #
    # assignment - The Assignment that will own the AssignmentRepo
    # user       - The User that the AssignmentRepo will belong to
    # retries    - The number of times the job will automatically retry
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform(assignment, user, retries: 0)
      start = Time.zone.now
      invite_status = assignment.invitation.status(user)
      return unless invite_status.waiting?
      invite_status.creating_repo!

      broadcast_message(
        message: CREATE_REPO,
        assignment: assignment,
        user: user,
        invite_status: invite_status,
        status_text: CREATE_REPO.chomp(".")
      )
      create_assignment_repo(assignment, user)
      report_time(start)

      GitHubClassroom.statsd.increment("v2_exercise_repo.create.success")
      if assignment.starter_code?
        invite_status.importing_starter_code!
        broadcast_message(
          message: IMPORT_STARTER_CODE,
          assignment: assignment,
          user: user,
          invite_status: invite_status,
          status_text: "Import started"
        )
        GitHubClassroom.statsd.increment("exercise_repo.import.started")
      else
        invite_status.completed!
        broadcast_message(
          message: Creator::REPOSITORY_CREATION_COMPLETE,
          assignment: assignment,
          user: user,
          invite_status: invite_status,
          status_text: "Completed"
        )
      end
    rescue Creator::Result::Error => err
      handle_error(err, assignment, user, invite_status, retries)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

    private

    # Creates an AssignmentRepo with an associated GitHub repo
    # If creation fails, it deletes the GitHub repo
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def create_assignment_repo(assignment, user)
      creator = Creator.new(assignment: assignment, user: user)
      creator.verify_organization_has_private_repos_available!

      github_repository = creator.create_github_repository!

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        user: user
      )
      creator.add_user_to_repository!(assignment_repo.github_repo_id)
      creator.push_starter_code!(assignment_repo.github_repo_id) if assignment.starter_code?

      assignment_repo.save!
      assignment_repo
    rescue ActiveRecord::RecordInvalid => err
      creator.delete_github_repository(assignment_repo.try(:github_repo_id))
      logger.warn(err.message)
      raise Creator::Result::Error, Creator::DEFAULT_ERROR_MESSAGE
    rescue Creator::Result::Error => err
      creator.delete_github_repository(assignment_repo.try(:github_repo_id))
      raise err
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    # Given an error, retries the job if retries are positive
    # or broadcasts a failure to the user
    #
    # rubocop:disable MethodLength
    def handle_error(err, assignment, user, invite_status, retries)
      logger.warn(err.message)
      if retries.positive?
        invite_status.waiting!
        CreateGitHubRepositoryJob.perform_later(assignment, user, retries: retries - 1)
      else
        invite_status.errored_creating_repo!
        broadcast_message(
          type: :error,
          message: err,
          assignment: assignment,
          user: user,
          invite_status: invite_status,
          status_text: "Failed"
        )
        report_error(err)
      end
    end
    # rubocop:enable MethodLength

    # Broadcasts a ActionCable message with a status to the given user
    #
    # rubocop:disable ParameterLists
    def broadcast_message(type: :text, message:, assignment:, user:, invite_status:, status_text:)
      raise ArgumentError unless %i[text error].include?(type)
      broadcast_args = {
        status: invite_status.status,
        status_text: status_text
      }
      broadcast_args[type] = message
      ActionCable.server.broadcast(
        RepositoryCreationStatusChannel.channel(user_id: user.id, assignment_id: assignment.id),
        broadcast_args
      )
    end
    # rubocop:enable ParameterLists

    # Reports the elapsed time to Datadog
    #
    def report_time(start_time)
      duration_in_millseconds = (Time.zone.now - start_time) * 1_000
      GitHubClassroom.statsd.timing("v2_exercise_repo.create.time", duration_in_millseconds)
    end

    # Maps the type of error to a Datadog error
    #
    def report_error(err)
      case err.message
      when Creator::REPOSITORY_CREATION_FAILED
        GitHubClassroom.statsd.increment("v2_exercise_repo.create.repo.fail")
      when Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED
        GitHubClassroom.statsd.increment("v2_exercise_repo.create.adding_collaborator.fail")
      when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
        GitHubClassroom.statsd.increment("v2_exercise_repo.create.importing_starter_code.fail")
      else
        GitHubClassroom.statsd.increment("v2_exercise_repo.create.fail")
      end
    end
  end
end
