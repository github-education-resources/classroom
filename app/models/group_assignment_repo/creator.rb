# frozen_string_literal: true

class GroupAssignmentRepo
  class Creator
    include RepoCreatable

    DEFAULT_ERROR_MESSAGE                   = "Group assignment could not be created, please try again."
    REPOSITORY_CREATION_FAILED              = "GitHub repository could not be created, please try again."
    REPOSITORY_STARTER_CODE_IMPORT_FAILED   = "We were not able to import you the starter code to your group assignment, please try again." # rubocop:disable LineLength
    REPOSITORY_TEAM_ADDITION_FAILED         = "We were not able to add the team to the repository, please try again." # rubocop:disable LineLength
    REPOSITORY_CREATION_COMPLETE            = "Your GitHub repository was created."
    IMPORT_ONGOING                          = "Your GitHub repository is importing starter code."
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"

    def self.perform(group_assignment:, group:)
      new(group_assignment: group_assignment, group: group).perform
    end

    attr_reader :group_assignment, :group, :organization, :invite_status, :reporter, :slug
    delegate :broadcast_message, :broadcast_error, :report_time, to: :reporter
    alias assignment group_assignment

    def initialize(group_assignment:, group:)
      @group_assignment = group_assignment
      @group            = group
      @organization     = group_assignment.organization
      @invite_status    = group_assignment.invitation.status(group)
      @reporter         = Reporter.new(self)
      @slug             = group.github_team.slug_no_cache
    end

    # Creates a GroupAssignmentRepo with an associated GitHub repo
    # If creation fails, it deletes the GitHub repo
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform
      start = Time.zone.now
      invite_status.creating_repo!
      broadcast_message(CREATE_REPO)
      verify_organization_has_private_repos_available!
      github_repository = create_github_repository!

      group_assignment_repo = group_assignment.group_assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        group: group
      )

      add_team_to_github_repository!(github_repository.id)

      if group_assignment.starter_code?
        push_starter_code!(group_assignment_repo.github_repo_id)
      end

      begin
        group_assignment_repo.save!
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger.warn(error.message)
        raise Result::Error.new DEFAULT_ERROR_MESSAGE, error.message
      end

      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.success")

      if group_assignment.starter_code?
        invite_status.importing_starter_code!
        broadcast_message(
          IMPORT_STARTER_CODE,
          group_assignment_repo&.github_repository&.html_url
        )
        GitHubClassroom.statsd.increment("group_exercise_repo.import.started")
      else
        invite_status.completed!
        broadcast_message(REPOSITORY_CREATION_COMPLETE)
      end

      duration_in_millseconds = (Time.zone.now - start) * 1_000
      GitHubClassroom.statsd.timing("exercise_repo.create.time", duration_in_millseconds)
      GitHubClassroom.statsd.increment("exercise_repo.create.success")

      Result.success(group_assignment_repo)
    rescue Result::Error => error
      delete_github_repository(group_assignment_repo&.github_repo_id)
      GitHubClassroom.statsd.increment("exercise_repo.create.fail")
      Result.failed(error.message)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

    def add_team_to_github_repository!(github_repository_id)
      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      github_team       = GitHubTeam.new(organization.github_client, group.github_team_id)

      github_team.add_team_repository(github_repository.full_name, repository_permissions)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_TEAM_ADDITION_FAILED, error.message
    end
  end
end
