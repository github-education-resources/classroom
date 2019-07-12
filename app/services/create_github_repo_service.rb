# frozen_string_literal: true

class CreateGitHubRepoService
  attr_reader :entity, :stats_sender
  delegate :assignment, :collaborator, :organization, :invite_status, to: :entity

  def initialize(assignment, collaborator)
    @entity = Entity.build(assignment, collaborator)
    @stats_sender = StatsSender.new(@entity)
  end

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def perform
    start = Time.zone.now
    invite_status.creating_repo!
    Broadcaster.call(entity, :create_repo, :text)

    verify_organization_has_private_repos_available!

    github_repository = create_github_repository!
    assignment_repo = create_assignment_repo!(github_repository)
    stats_sender.repo_creation_success

    add_collaborator_to_github_repository!(github_repository)

    if assignment.starter_code?
      push_starter_code!(github_repository)
      invite_status.importing_starter_code!
      Broadcaster.call(entity, :importing_starter_code, :text, assignment_repo&.github_repository&.html_url)
      stats_sender.import_started
    else
      invite_status.completed!
      Broadcaster.call(entity, :repository_creation_complete, :text)
    end

    stats_sender.timing(start)
    stats_sender.default_success
    Result.success(assignment_repo)
  rescue Result::Error => error
    delete_github_repository(assignment_repo&.github_repo_id)
    stats_sender.default_failure
    Result.failed(error.message)
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def create_github_repository!
    options = {
      private: assignment.private?,
      description: "#{entity.repo_name} created by GitHub Classroom"
    }

    organization.github_organization.create_repository(entity.repo_name, options)
  rescue GitHub::Error => error
    raise Result::Error.new REPOSITORY_CREATION_FAILED, error.message
  end

  def create_assignment_repo!(github_repository)
    assignment_repo_attrs = {
      github_repo_id: github_repository.id,
      github_global_relay_id: github_repository.node_id
    }
    assignment_repo_attrs[entity.humanize] = entity.collaborator
    assignment_repo = entity.repos.build(assignment_repo_attrs)
    assignment_repo.save!
    assignment_repo
  rescue ActiveRecord::RecordInvalid => error
    raise Result::Error.new errors(:default), error.message
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
  def push_starter_code!(assignment_repository)
    client = assignment.creator.github_client
    starter_code_repo_id = assignment.starter_code_repo_id
    starter_code_repository = GitHubRepository.new(client, starter_code_repo_id)

    assignment_repository.get_starter_code_from(starter_code_repository)
  rescue GitHub::Error => error
    raise Result::Error.new errors(:collaborator_addition_failed), error.message
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

  def add_collaborator_to_github_repository!(github_repository)
    send("add_#{entity.humanize}_to_github_repository!", github_repository)
  rescue GitHub::Error => error
    raise Result::Error.new errors(:collaborator_addition_failed), error.message
  end

  private

  def add_group_to_github_repository!(github_repository)
    github_team = GitHubTeam.new(organization.github_client, entity.collaborator.github_team_id)
    github_team.add_team_repository(github_repository.full_name, repository_permissions)
  end

  def add_user_to_github_repository!(github_repository)
    invitation = github_repository.invite(entity.slug, repository_permissions)
    entity.collaborator.github_user.accept_repository_invitation(invitation.id) if invitation.present?
  end

  def repository_permissions
    {}.tap do |options|
      options[:permission] = "admin" if entity.admin?
    end
  end

  # rubocop:disable LineLength
  def errors(error_message)
    messages = {
      default: "#{entity.assignment_type} could not be created, please try again.",
      repository_creation_failed: "GitHub repository could not be created, please try again.",
      starter_code_import_failed: "We were not able to import you the starter code to your #{entity.assignment_type.downcase}, please try again.",
      collaborator_addition_failed: "We were not able to add the #{entity.humanize} to the #{entity.assignment_type.downcase}, please try again."
    }
    messages[error_message]
  end
  # rubocop:enable LineLength
end
