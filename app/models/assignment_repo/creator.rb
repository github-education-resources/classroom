# frozen_string_literal: true
class AssignmentRepo
  class Creator
    DEFAULT_ERROR_MESSAGE = 'Assignment could not be created, please try again'

    class Result
      attr_reader :assignment, :invitee, :organization

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
    # invitee    - The User that the AssignmentRepo will belong to.
    #
    # Returns a AssignmentRepo::Creator::Result.
    def self.perform(assignment:, invitee:)
      new(assignment: assignment, invitee: invitee).perform
    end

    def initialize(assignment:, invitee:)
      @assignment   = assignment
      @invitee      = invitee
      @organization = assignment.organization
    end

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform
      verify_organization_has_private_repos_available!

      assignment_repo = assignment.assignment_repos.build(
        github_repo_id: create_github_repository!,
        user: invitee
      )

      add_invitee_to_repository!(assignment_repo.github_repo_id)

      if assignment.starter_code?
        push_starter_code!(assignment_repo.github_repo_id)
      end

      begin
        assignment_repo.save!
      rescue ActiveRecord::RecordInvalid
        raise Result::Error, DEFAULT_ERROR_MESSAGE
      end
    rescue Result::Error => err
      delete_github_repository(assignment_repo.github_repo_id)
      Result.failed(err.message)
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    private

    # Internal: Add the invitee User to the GitHub repository
    # as a collaborator.
    #
    # NOTE: Because of the API changes https://developer.github.com/changes/2016-06-14-repository-invitations
    # we now have create an invitation for the repository, and then have the student accept it with their
    # own token.
    #
    # Returns true if successful, otherwise raises a Result::Error
    def add_invitee_to_repository!(github_repository_id)
      options = {}.tap { |opt| opt[:permissions] = 'admin' if assignment.students_are_repo_admins? }

      github_repository = GitHubRepository.new(organization.github_client, github_repository_id)
      invitation_id = github_repository.invite(invitee.github_user.login_no_cache, options)

      invitee.github_user.accept_repository_invitation(invitation_id)
    rescue GitHub::Error
      raise Result::Error, DEFAULT_ERROR_MESSAGE
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

      github_organization.create_repository(repository_name, options).id
    rescue GitHub::Error
      raise Result::Error, 'GitHub repository could not be created, please try again'
    end

    def delete_github_repository(github_repo_id)
      return true if github_repo_id.nil?
      organization.github_organization.delete_github_repository(github_repo_id)
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
    end

    # Internal: Ensure that we can make a private repository on GitHub.
    #
    # Returns True or raises a Result::Error with a helpful message.
    def verify_organization_has_private_repos_available!
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
      repository_name = "#{assignemnt.slug}-#{invitee.github_user.login_no_cache}"

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
  end
end
