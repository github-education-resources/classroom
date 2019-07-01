# frozen_string_literal: true

module RepoCreatable
  extend ActiveSupport::Concern
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
    raise self.class::Result::Error.new self.class::REPOSITORY_CREATION_FAILED, error.message
  end

  def delete_github_repository(github_repo_id)
    return true if github_repo_id.nil?
    organization.github_organization.delete_repository(github_repo_id)
  rescue GitHub::Error
    true
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
    raise self.class::Result::Error.new self.class::REPOSITORY_STARTER_CODE_IMPORT_FAILED, error.message
  end

  # Public: Ensure that we can make a private repository on GitHub.
  #
  # Returns True or raises a Result::Error with a helpful message.
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable MethodLength
  def verify_organization_has_private_repos_available!
    return true if assignment.public?

    begin
      github_organization_plan = GitHubOrganization.new(organization.github_client, organization.github_id).plan
    rescue GitHub::Error => error
      raise self.class::Result::Error, error.message
    end

    owned_private_repos = github_organization_plan[:owned_private_repos]
    private_repos       = github_organization_plan[:private_repos]

    return true if owned_private_repos < private_repos

    error_message = <<~ERROR
      Cannot make this private assignment, your limit of #{private_repos}
      #{'repository'.pluralize(private_repos)} has been reached. You can request
      a larger plan for free at https://education.github.com/discount
      ERROR

    raise self.class::Result::Error, error_message
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable MethodLength

  private

  #####################################
  # GitHub repository name generation #
  #####################################
  def generate_github_repository_name
    suffix_count = 0

    owner           = organization.github_organization.login_no_cache
    repository_name = "#{assignment.slug}-#{slug}"

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

  def repository_permissions
    {}.tap do |options|
      options[:permission] = "admin" if assignment.students_are_repo_admins?
    end
  end
end
