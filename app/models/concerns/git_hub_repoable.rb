module GitHubRepoable
  extend ActiveSupport::Concern

  # Public
  #
  def add_team_to_github_repository
    github_repository = GitHubRepository.new(organization.github_client, github_repo_id)
    github_team       = GitHubTeam.new(organization.github_client, github_team_id)

    github_team.add_team_repository(github_repository.full_name)
  end

  def add_user_as_collaborator
    github_user = GitHubUser.new(user.github_client, user.uid)
    repository  = GitHubRepository.new(organization.github_client, github_repo_id)

    delete_github_repository_on_failure { repository.add_collaborator(github_user.login) }
  end

  # Public
  #
  def create_github_repository
    repo_description = "#{repo_name} created by Classroom for GitHub"
    github_repository = github_organization.create_repository(repo_name,
                                                              private: self.private?,
                                                              description: repo_description)
    self.github_repo_id = github_repository.id
  end

  # Public
  #
  def destroy_github_repository
    github_organization.delete_repository(github_repo_id)
  end

  # Public
  #
  def delete_github_repository_on_failure
    yield
  rescue GitHub::Error
    silently_destroy_github_repository
    raise GitHub::Error, 'Assignment failed to be created'
  end

  # Public
  #
  def silently_destroy_github_repository
    destroy_github_repository
    true # Destroy ActiveRecord object even if we fail to delete the repository
  end

  # Public
  #
  def push_starter_code
    return true unless starter_code_repo_id

    client = creator.github_client

    assignment_repository   = GitHubRepository.new(client, github_repo_id)
    starter_code_repository = GitHubRepository.new(client, starter_code_repo_id)

    delete_github_repository_on_failure do
      assignment_repository.get_starter_code_from(starter_code_repository)
    end
  end

  # Internal
  #
  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end
end
