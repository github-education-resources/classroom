# frozen_string_literal: true

class GroupAssignmentRepo
  # rubocop:disable Metrics/ClassLength
  class Creator
    DEFAULT_ERROR_MESSAGE                   = "Group assignment could not be created, please try again."
    REPOSITORY_CREATION_FAILED              = "GitHub repository could not be created, please try again."
    REPOSITORY_STARTER_CODE_IMPORT_FAILED   = "We were not able to import you the starter code to your group assignment, please try again." # rubocop:disable LineLength
    REPOSITORY_TEAM_ADDITION_FAILED         = "We were not able to add the team to the repository, please try again." # rubocop:disable LineLength
    REPOSITORY_CREATION_COMPLETE            = "Your GitHub repository was created."
    TEMPLATE_REPOSITORY_CREATION_FAILED     = "GitHub repository could not be created from template, please try again."
    IMPORT_ONGOING                          = "Your GitHub repository is importing starter code."
    CREATE_REPO         = "Creating repository"
    ADDING_COLLABORATOR = "Adding collaborator"
    IMPORT_STARTER_CODE = "Importing starter code"
    CREATE_COMPLETE     = "Your GitHub repository was created."
    GITHUB_API_HOST     = "https://api.github.com"
    TEMPLATE_REPOS_API_PREVIEW = "application/vnd.github.baptiste-preview"

    def self.perform(group_assignment:, group:)
      new(group_assignment: group_assignment, group: group).perform
    end

    attr_reader :group_assignment, :group, :organization, :invite_status, :reporter
    delegate :broadcast_message, :broadcast_error, :report_time, to: :reporter

    def initialize(group_assignment:, group:)
      @group_assignment = group_assignment
      @group            = group
      @organization     = group_assignment.organization
      @invite_status    = group_assignment.invitation.status(group)
      @reporter         = Reporter.new(self)
    end

    # Creates a GroupAssignmentRepo with an associated GitHub repo
    # If creation fails, it deletes the GitHub repo
    #
    # rubocop:disable MethodLength, AbcSize, CyclomaticComplexity, PerceivedComplexity
    def perform
      start = Time.zone.now
      invite_status.creating_repo!
      broadcast_message(CREATE_REPO)
      verify_organization_has_private_repos_available!

      if group_assignment.organization.feature_enabled?(:template_repos) && group_assignment.use_template_repos?
        github_repository = create_github_repository_from_template!
      else
        github_repository = create_github_repository!
      end

      if group_assignment.use_template_repos?
        GitHubClassroom.statsd.increment("group_exercise_repo.create.repo.with_templates.success")
      end

      group_assignment_repo = group_assignment.group_assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        group: group
      )

      add_team_to_github_repository!(github_repository.id)

      push_starter_code!(group_assignment_repo.github_repo_id) if group_assignment.use_importer?

      begin
        group_assignment_repo.save!
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger.warn(error.message)
        raise Result::Error.new DEFAULT_ERROR_MESSAGE, error.message
      end

      GitHubClassroom.statsd.increment("v2_group_exercise_repo.create.success")
      GitHubClassroom.statsd.increment("group_exercise_repo.create.success")

      if group_assignment.use_importer?
        invite_status.importing_starter_code!
        broadcast_message(
          IMPORT_STARTER_CODE,
          group_assignment_repo&.github_repository&.html_url
        )
        GitHubClassroom.statsd.increment("group_exercise_repo.import.started")
      else
        invite_status.completed!
        broadcast_message(CREATE_COMPLETE)
      end

      report_time(start, group_assignment)
      GitHubClassroom.statsd.increment("exercise_repo.create.success")

      Result.success(group_assignment_repo)
    rescue Result::Error => error
      delete_github_repository(group_assignment_repo&.github_repo_id)
      GitHubClassroom.statsd.increment("exercise_repo.create.fail")
      Result.failed(error.message)
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize

    def create_github_repository!
      repository_name = generate_github_repository_name
      organization.github_organization.create_repository(
        repository_name,
        private: group_assignment.private?,
        description: "#{repository_name} created by GitHub Classroom"
      )
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_CREATION_FAILED, error.message
    end

    # rubocop:disable MethodLength, AbcSize
    def create_github_repository_from_template!
      GitHubClassroom.statsd.increment("group_exercise_repo.create.repo.with_templates.started")
      repository_name = generate_github_repository_name
      client = group_assignment.creator.github_client
      options = {
        name: repository_name,
        owner: organization.github_organization.login,
        private: group_assignment.private?,
        description: "#{repository_name} created by GitHub Classroom",
        accept: TEMPLATE_REPOS_API_PREVIEW
      }

      client.post("#{GITHUB_API_HOST}/repositories/#{group_assignment.starter_code_repo_id}/generate", options)
    rescue GitHub::Error => error
      GitHubClassroom.statsd.increment("group_exercise_repo.create.repo.with_templates.failed")
      raise Result::Error.new TEMPLATE_REPOSITORY_CREATION_FAILED, error.message
    end

    def add_team_to_github_repository!(github_repository_id)
      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      github_team       = GitHubTeam.new(organization.github_client, group.github_team_id)

      github_team.add_team_repository(github_repository.full_name, repository_permissions)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_TEAM_ADDITION_FAILED, error.message
    end

    def push_starter_code!(github_repository_id)
      client                  = group_assignment.creator.github_client
      starter_code_repo_id    = group_assignment.starter_code_repo_id
      assignment_repository   = GitHubRepository.new(client, github_repository_id)
      starter_code_repository = GitHubRepository.new(client, starter_code_repo_id)

      assignment_repository.get_starter_code_from(starter_code_repository)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_STARTER_CODE_IMPORT_FAILED, error.message
    end

    def delete_github_repository(github_repository_id)
      return true if github_repository_id.nil?
      organization.github_organization.delete_repository(github_repository_id)
    rescue GitHub::Error
      true
    end

    def verify_organization_has_private_repos_available!
      return true if group_assignment.public?

      begin
        github_organization_plan = GitHubOrganization.new(organization.github_client, organization.github_id).plan
      rescue GitHub::Error => error
        raise Result::Error, error.message
      end

      owned_private_repos = github_organization_plan[:owned_private_repos]
      private_repos       = github_organization_plan[:private_repos]

      return true if owned_private_repos < private_repos

      # TODO: make message consistent for both assignment types
      error_message = <<-ERROR
        Cannot make a private repository for this assignment, the organization has
        a limit of #{private_repos} #{'repository'.pluralize(private_repos)}.
        Please let the organization owner know that they can either upgrade their
        limit or, if the owner qualifies, request a larger plan for free at
        <a href='https://education.github.com/discount'>https://education.github.com/discount</a>
      ERROR

      raise Result::Error, error_message
    end
    # rubocop:enable MethodLength
    # rubocop:enable Metrics/AbcSize

    private

    def repository_permissions
      {
        permission: group_assignment.students_are_repo_admins? ? "admin" : "push"
      }
    end

    # rubocop:disable AbcSize
    def generate_github_repository_name
      suffix_count    = 0
      owner           = organization.github_organization.login_no_cache
      repository_name = "#{group_assignment.slug}-#{group.github_team.slug_no_cache}"
      loop do
        name = "#{owner}/#{suffixed_repo_name(repository_name, suffix_count)}"
        break unless GitHubRepository.present?(organization.github_client, name)
        suffix_count += 1
      end

      suffixed_repo_name(repository_name, suffix_count)
    end
    # rubocop:enable AbcSize

    def suffixed_repo_name(repository_name, suffix_count)
      return repository_name if suffix_count.zero?

      suffix = "-#{suffix_count}"
      repository_name.truncate(100 - suffix.length, omission: "") + suffix
    end
  end
  # rubocop:enable Metrics/ClassLength
end
