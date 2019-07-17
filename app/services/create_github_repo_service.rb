# frozen_string_literal: true

# rubocop:disable ClassLength
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

    add_collaborator_to_github_repository!(github_repository)

    if assignment.starter_code?
      push_starter_code!(github_repository)
      invite_status.importing_starter_code!
      Broadcaster.call(entity, :importing_starter_code, :text, assignment_repo&.github_repository&.html_url)
      stats_sender.report(:import_started)
    else
      invite_status.completed!
      Broadcaster.call(entity, :repository_creation_complete, :text)
    end

    stats_sender.timing(start)
    stats_sender.report(:success)
    Result.success(assignment_repo, entity)
  rescue Result::Error => error
    repo_id = assignment_repo&.github_repo_id || github_repository&.id
    delete_github_repository(repo_id)
    Result.failed(error.message, entity)
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  # Public: Creates a new GitHub Repository based on assignment name and privacy details.
  #
  # Returns created GitHubRepository object or raises a Result::Error on failure.
  def create_github_repository!
    options = {
      private: assignment.private?,
      description: "#{entity.repo_name} created by GitHub Classroom"
    }

    organization.github_organization.create_repository(entity.repo_name, options)
  rescue GitHub::Error => error
    raise Result::Error.new errors(:repository_creation_failed), error.message
  end

  # Public: Creates a new AssignmentRepo/GroupAssignmentRepo object
  #         with github_repository id and relay id.
  #
  # github_repository - GitHubRepository object of the newly created repo.
  #
  # Returns the created AssignmentRepo/GroupAssignmentRepo object
  # or raises a Result::Error on failure
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
  #         repository.
  #
  # assignment_repository - GitHubRepository in which starter code is to be imported.
  #
  # Returns true of raises a Result::Error.
  def push_starter_code!(assignment_repository)
    client = assignment.creator.github_client
    starter_code_repo_id = assignment.starter_code_repo_id
    starter_code_repository = GitHubRepository.new(client, starter_code_repo_id)

    assignment_repository.get_starter_code_from(starter_code_repository)
  rescue GitHub::Error => error
    raise Result::Error.new errors(:starter_code_import_failed), error.message
  end

  # Public: Ensure that we can make a private repository on GitHub.
  #
  # Returns True or raises a Result::Error with a helpful message.
  # rubocop:disable Metrics/AbcSize
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
    raise Result::Error, errors(:private_repos_not_available, github_organization_plan)
  end
  # rubocop:enable Metrics/AbcSize

  # Public: Add user/team to the GitHubRepository based on the type of assignment.
  #         Calls #add_user_to_github_repository! if it is an Assignment.
  #         Calls #add_group_to_github_repository! if it is a GroupAssignment.
  #
  # github_repository - GitHubRepository in which we need to add collaborator.
  #
  # Returns true if collaborator added or raises a Result::Error.
  def add_collaborator_to_github_repository!(github_repository)
    send("add_#{entity.humanize}_to_github_repository!", github_repository)
  rescue GitHub::Error => error
    raise Result::Error.new errors(:collaborator_addition_failed), error.message
  end

  # Maps the type of error to a Datadog error
  #
  def report_error(err)
    case err
    when /^#{errors(:repository_creation_failed)}/
      stats_sender.report(:repository_creation_failed)
    when /^#{errors(:collaborator_addition_failed)}/
      stats_sender.report(:collaborator_addition_failed)
    when /^#{errors(:starter_code_import_failed)}/
      stats_sender.report(:starter_code_import_failed)
    else
      stats_sender.report(:failure)
    end
  end

  private

  # Internal: Creates a new team on GitHub and adds it to the repository.
  #
  # github_repository - GitHubRepository in which we need to add the team.
  #
  # Returns true if collaborator added or raises a GitHub::Error.
  def add_group_to_github_repository!(github_repository)
    github_team = GitHubTeam.new(organization.github_client, entity.collaborator.github_team_id)
    github_team.add_team_repository(github_repository.full_name, repository_permissions)
  end

  # Internal: Creates a new invitation for the GitHubRepository and then accepts it on behalf
  #           of the user.
  #
  # github_repository - GitHubRepository in which we need to add the user.
  #
  # Returns true if collaborator added or raises a GitHub::Error.
  def add_user_to_github_repository!(github_repository)
    invitation = github_repository.invite(entity.slug, repository_permissions)
    entity.collaborator.github_user.accept_repository_invitation(invitation.id) if invitation.present?
  end

  def repository_permissions
    {}.tap do |options|
      options[:permission] = "admin" if entity.admin?
    end
  end

  # Internal: Method for error messages, modifies error messages based on the type of assignment.
  #
  # error_message - A symbol for getting the  appropriate error message.
  # rubocop:disable LineLength
  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def errors(error_message, options = {})
    messages = {
      default: "#{entity.assignment_type.humanize} could not be created, please try again.",
      repository_creation_failed: "GitHub repository could not be created, please try again.",
      starter_code_import_failed: "We were not able to import you the starter code to your #{entity.assignment_type.humanize}, please try again.",
      collaborator_addition_failed: "We were not able to add the #{entity.humanize} to the #{entity.assignment_type.humanize}, please try again.",
      private_repos_not_available: <<-ERROR
      Cannot make this private assignment, your limit of #{options[:private_repos]}
       #{'repository'.pluralize(options[:private_repos])} has been reached. You can request
       a larger plan for free at https://education.github.com/discount
       ERROR
    }
    messages[error_message] || messages[:default]
  end
  # rubocop:enable LineLength
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize
end
# rubocop:enable ClassLength
