# frozen_string_literal: true

class AssignmentRepo
  # rubocop:disable ClassLength
  class Creator
    DEFAULT_ERROR_MESSAGE                   = "Assignment could not be created, please try again."
    REPOSITORY_CREATION_FAILED              = "GitHub repository could not be created, please try again."
    REPOSITORY_STARTER_CODE_IMPORT_FAILED   = "We were not able to import you the starter code to your assignment, please try again." # rubocop:disable LineLength
    REPOSITORY_COLLABORATOR_ADDITION_FAILED = "We were not able to add you to the Assignment as a collaborator, please try again." # rubocop:disable LineLength
    REPOSITORY_CREATION_COMPLETE            = "Your GitHub repository was created."
    TEMPLATE_REPOSITORY_CREATION_FAILED     = "GitHub repository could not be created from template, please try again."
    IMPORT_ONGOING                          = "Your GitHub repository is importing starter code."
    CREATE_REPO                             = "Creating GitHub repository."
    IMPORT_STARTER_CODE                     = "Importing starter code."

    attr_reader :assignment, :user, :organization, :invite_status, :reporter
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
      @assignment   = assignment
      @user         = user
      @organization = assignment.organization
      @invite_status = assignment.invitation.status(user)
      @reporter = Reporter.new(self)
    end

    # rubocop:disable MethodLength, AbcSize, CyclomaticComplexity, PerceivedComplexity
    def perform
      start = Time.zone.now
      invite_status.creating_repo!

      broadcast_message(
        message: CREATE_REPO,
        status_text: CREATE_REPO.chomp(".")
      )
      verify_organization_has_private_repos_available!

      github_repository = if assignment.organization.feature_enabled?(:template_repos) && assignment.use_template_repos?
                            create_github_repository_from_template!
                          else
                            create_github_repository!
                          end

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: github_repository.id,
        github_global_relay_id: github_repository.node_id,
        user: user
      )

      add_user_to_repository!(assignment_repo.github_repo_id)

      push_starter_code!(assignment_repo.github_repo_id) if assignment.use_importer?

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger.warn(error.message)
        raise Result::Error.new DEFAULT_ERROR_MESSAGE, error.message
      end
      report_time(start, assignment)

      GitHubClassroom.statsd.increment("v2_exercise_repo.create.success")
      GitHubClassroom.statsd.increment("exercise_repo.create.success")
      if assignment.use_importer?
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

      Result.success(assignment_repo)
    rescue Result::Error => error
      delete_github_repository(assignment_repo.try(:github_repo_id))
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
      options = {}.tap { |opt| opt[:permission] = "admin" if assignment.students_are_repo_admins? }

      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      invitation = github_repository.invite(user.github_user.login(use_cache: false), options)

      user.github_user.accept_repository_invitation(invitation.id) if invitation.present?
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_COLLABORATOR_ADDITION_FAILED, error.message
    end
    # rubocop:enable Metrics/AbcSize

    # Public: Create the GitHub repository for the AssignmentRepo.
    #
    # Returns an Integer ID or raises a Result::Error
    def create_github_repository!
      repository_name = generate_github_repository_name

      options = {
        private: assignment.private?,
        description: "#{repository_name} created by GitHub Classroom"
      }

      organization.github_organization.create_repository(repository_name, options)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_CREATION_FAILED, error.message
    end

    def delete_github_repository(github_repo_id)
      return true if github_repo_id.nil?
      organization.github_organization.delete_repository(github_repo_id)
    rescue GitHub::Error
      true
    end

    # Public: Clone the GitHub template repository for the AssignmentRepo.
    #
    # Returns an Integer ID or raises a Result::Error
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create_github_repository_from_template!
      client = assignment.creator.github_client
      repository_name = generate_github_repository_name
      options = {
        name: repository_name,
        owner: organization.github_organization.login,
        private: assignment.private?,
        description: "#{repository_name} created by GitHub Classroom",
        accept: "application/vnd.github.baptiste-preview"
      }

      client.post("https://api.github.com/repositories/#{assignment.starter_code_repo_id}/generate", options)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_CREATION_FAILED, error.message
    end

    # Public: Push starter code to the newly created GitHub
    # repository.
    #
    # github_repo_id - The Integer id of the GitHub repository.
    #
    # Returns true of raises a Result::Error.
    def push_starter_code!(github_repo_id)
      client = assignment.creator.github_client
      starter_code_repo_id = assignment.starter_code_repo_id

      assignment_repository   = GitHubRepository.new(client, github_repo_id)
      starter_code_repository = GitHubRepository.new(client, starter_code_repo_id)

      assignment_repository.get_starter_code_from(starter_code_repository)
    rescue GitHub::Error => error
      raise Result::Error.new REPOSITORY_STARTER_CODE_IMPORT_FAILED, error.message
    end

    # Public: Ensure that we can make a private repository on GitHub.
    #
    # Returns True or raises a Result::Error with a helpful message.
    def verify_organization_has_private_repos_available!
      return true if assignment.public?

      begin
        github_organization_plan = GitHubOrganization.new(organization.github_client, organization.github_id).plan
      rescue GitHub::Error => error
        raise Result::Error, error.message
      end

      owned_private_repos = github_organization_plan[:owned_private_repos]
      private_repos       = github_organization_plan[:private_repos]

      return true if owned_private_repos < private_repos

      error_message = <<~ERROR
        Cannot make this private assignment, your limit of #{private_repos}
        #{'repository'.pluralize(private_repos)} has been reached. You can request
        a larger plan for free at https://education.github.com/discount
      ERROR

      raise Result::Error, error_message
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable MethodLength

    private

    #####################################
    # GitHub repository name generation #
    #####################################

    # rubocop:disable AbcSize
    def generate_github_repository_name
      suffix_count = 0

      owner           = organization.github_organization.login_no_cache
      repository_name = "#{assignment.slug}-#{user.github_user.login(use_cache: false)}"

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
  # rubocop:enable ClassLength
end
