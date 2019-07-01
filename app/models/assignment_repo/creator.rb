# frozen_string_literal: true

class AssignmentRepo
  class Creator
    include RepoCreatable

    DEFAULT_ERROR_MESSAGE                   = "Assignment could not be created, please try again."
    REPOSITORY_CREATION_FAILED              = "GitHub repository could not be created, please try again."
    REPOSITORY_STARTER_CODE_IMPORT_FAILED   = "We were not able to import you the starter code to your assignment, please try again." # rubocop:disable LineLength
    REPOSITORY_COLLABORATOR_ADDITION_FAILED = "We were not able to add you to the Assignment as a collaborator, please try again." # rubocop:disable LineLength
    REPOSITORY_CREATION_COMPLETE            = "Your GitHub repository was created."
    IMPORT_ONGOING                          = "Your GitHub repository is importing starter code."
    CREATE_REPO                             = "Creating GitHub repository."
    IMPORT_STARTER_CODE                     = "Importing starter code."

    attr_reader :assignment, :user, :organization, :invite_status, :reporter, :slug
    delegate :broadcast_message, :report_time, :report_error, to: :reporter
    # Public: Create an AssignmentRepo.
    #
    # assignment - The Assignment that will own the AssignmentRepo.
    # user       - The User that the AssignmentRepo will belong to.
    #
    # Returns a AssignmentRepo::Creator::Result.
    def self.perform(assignment:, user:)
      new(assignment: assignment, user: user).perform
    end

    def initialize(assignment:, user:)
      @assignment     = assignment
      @user           = user
      @organization   = assignment.organization
      @invite_status  = assignment.invitation.status(user)
      @reporter       = Reporter.new(self)
      @slug           = user.github_user.login_no_cache
    end

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform
      start = Time.zone.now
      invite_status.creating_repo!

      broadcast_message(
        message: CREATE_REPO,
        status_text: CREATE_REPO.chomp(".")
      )
      verify_organization_has_private_repos_available!

      github_repository = create_github_repository!

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        user: user
      )

      add_user_to_repository!(assignment_repo.github_repo_id)

      if assignment.starter_code?
        push_starter_code!(assignment_repo.github_repo_id)
      end

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger.warn(error.message)
        raise Result::Error.new DEFAULT_ERROR_MESSAGE, error.message
      end
      report_time(start)

      GitHubClassroom.statsd.increment("v2_exercise_repo.create.success")
      if assignment.starter_code?
        invite_status.importing_starter_code!
        broadcast_message(
          message: IMPORT_STARTER_CODE,
          status_text: "Import started",
          repo_url: assignment_repo.github_repository.html_url
        )
        GitHubClassroom.statsd.increment("exercise_repo.import.started")
      else
        invite_status.completed!
        broadcast_message(
          message: REPOSITORY_CREATION_COMPLETE,
          status_text: "Completed"
        )
      end

      duration_in_millseconds = (Time.zone.now - start) * 1_000
      GitHubClassroom.statsd.timing("exercise_repo.create.time", duration_in_millseconds)
      GitHubClassroom.statsd.increment("exercise_repo.create.success")

      Result.success(assignment_repo)
    rescue Result::Error => error
      delete_github_repository(assignment_repo.try(:github_repo_id))
      GitHubClassroom.statsd.increment("exercise_repo.create.fail")
      Result.failed(error.message)
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    # Public: Add the User to the GitHub repository
    # as a collaborator.
    #
    # Returns true if successful, otherwise raises a Result::Error
    # rubocop:disable Metrics/AbcSize
    def add_user_to_repository!(github_repository_id)
      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      invitation = github_repository.invite(user.github_user.login_no_cache, repository_permissions)

      user.github_user.accept_repository_invitation(invitation.id) if invitation.present?
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_COLLABORATOR_ADDITION_FAILED, error.message
    end
    # rubocop:enable Metrics/AbcSize
  end
end
