# frozen_string_literal: true

class AssignmentRepo
  class Creator
    DEFAULT_ERROR_MESSAGE                   = 'Assignment could not be created, please try again'
    REPOSITORY_CREATION_FAILED              = 'GitHub repository could not be created, please try again'
    REPOSITORY_STARTER_CODE_IMPORT_FAILED   = 'We were not able to import you the starter code to your assignment, please try again.' # rubocop:disable LineLength
    REPOSITORY_COLLABORATOR_ADDITION_FAILED = 'We were not able to add you to the Assignment as a collaborator, please try again.' # rubocop:disable LineLength

    attr_reader :assignment, :user, :organization

    class Result
      class Error < StandardError; end

      def self.success(assignment_repo)
        new(:success, assignment_repo: assignment_repo)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :assignment_repo

      def initialize(status, assignment_repo: nil, error: nil)
        @status          = status
        @assignment_repo = assignment_repo
        @error           = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

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
    end

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform
      verify_organization_has_private_repos_available!

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: create_github_repository!,
        user: user
      )

      if assignment.starter_code?
        push_starter_code!(assignment_repo.github_repo_id)
      end

      add_user_to_repository!(assignment_repo.github_repo_id)

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid
        raise Result::Error, DEFAULT_ERROR_MESSAGE
      end

      Result.success(assignment_repo)
    rescue Result::Error => err
      delete_github_repository(assignment_repo.try(:github_repo_id))
      Result.failed(err.message)
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    private

    # Internal: Add the User to the GitHub repository
    # as a collaborator.
    #
    # Returns true if successful, otherwise raises a Result::Error
    def add_user_to_repository!(github_repository_id)
      options = {}.tap { |opt| opt[:permission] = 'admin' if assignment.students_are_repo_admins? }

      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      github_repository.add_collaborator(user.github_user.login_no_cache, options)
    rescue GitHub::Error
      raise Result::Error, REPOSITORY_COLLABORATOR_ADDITION_FAILED
    end

    # Internal: Create the GitHub repository for the AssignmentRepo.
    #
    # Returns an Integer ID or raises a Result::Error
    def create_github_repository!
      repository_name = generate_github_repository_name

      options = {
        private: assignment.private?,
        description: "#{repository_name} created by GitHub Classroom"
      }

      organization.github_organization.create_repository(repository_name, options).id
    rescue GitHub::Error
      raise Result::Error, REPOSITORY_CREATION_FAILED
    end

    def delete_github_repository(github_repo_id)
      return true if github_repo_id.nil?
      organization.github_organization.delete_repository(github_repo_id)
    rescue GitHub::Error
      true
    end

    # Internal: Push starter code to the newly created GitHub
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
      setup_repository(starter_code_repository, assignment_repository)
    rescue GitHub::Error
      raise Result::Error, REPOSITORY_STARTER_CODE_IMPORT_FAILED
    end

    # Internal: Ensure that we can make a private repository on GitHub.
    #
    # Returns True or raises a Result::Error with a helpful message.
    def verify_organization_has_private_repos_available!
      return true if assignment.public?

      github_organization_plan = GitHubOrganization.new(organization.github_client, organization.github_id).plan

      owned_private_repos = github_organization_plan[:owned_private_repos]
      private_repos       = github_organization_plan[:private_repos]

      return true if owned_private_repos < private_repos

      error_message = <<-ERROR
      Cannot make this private assignment, your limit of #{private_repos}
      #{'repository'.pluralize(private_repos)} has been reached. You can request
      a larger plan for free at https://education.github.com/discount
      ERROR

      raise Result::Error, error_message
    end

    #####################################
    # GitHub repository name generation #
    #####################################

    # rubocop:disable AbcSize
    def generate_github_repository_name
      suffix_count = 0

      owner           = organization.github_organization.login_no_cache
      repository_name = "#{assignment.slug}-#{user.github_user.login_no_cache}"

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
      repository_name.truncate(100 - suffix.length, omission: '') + suffix
    end

    # Handles assignment repository setup
    #
    # configs_repo    - GitHubRepository containing the configuration files
    # assignment_repo - GitHubRepository for which to perform the configuration
    #                   setups
    #
    # Returns nothing
    def setup_repository(configs_repo, assignment_repo)
      return unless configs_repo.classroom_configs?
      conf_tree = configs_repo.branch('github-classroom').commit.commit.tree.sha
      configs_repo.tree(conf_tree).tree.each do |conf|
        process_config(configs_repo, assignment_repo, conf)
      end

      wait_import_completion assignment_repo

      assignment_repo.remove_branch('github-classroom')
    end

    def wait_import_completion(github_repository)
      loop do
        break unless github_repository.import_progress[:status] != 'complete'
        sleep 5 # NOTE rate limits
      end
    end

    # Process the configurations separetly
    #
    # configs_repo    - GitHubRepository containing the configuration files
    # assignment_repo - GitHubRepository for which to perform the configuration
    #                   setups
    # conf            - GitObjects from of the 'github-classroom' branch tree
    #                   of the configs_repo
    #
    # Returns nothing
    def process_config(configs_repo, assignment_repo, conf)
      case conf.path
      when 'issues'
        gen_issues(configs_repo, assignment_repo, conf.sha)
      end
    end

    # Generates issues for the assignment_repo based on the configs
    #
    # configs_repo    - GitHubRepository containing the configuration files
    # assignment_repo - GitHubRepository for which to perform the configuration
    #                   setups
    # issues_tree     - sha of the 'issues' tree
    #
    # Returns nothing
    def gen_issues(configs_repo, assignment_repo, issues_tree)
      configs_repo.tree(issues_tree).tree.each do |issue|
        blob = configs_repo.blob(issue.sha)
        assignment_repo.add_issue(blob.data['title'], blob.body)
      end
    end
  end
end
