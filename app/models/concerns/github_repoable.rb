module GitHubRepoable
  extend ActiveSupport::Concern

  delegate :github_organization, to: :organization

  def github_repository
    @github_repository ||= GitHubRepository.new(id: github_repo_id, access_token: organization.access_token)
  end

  def add_team_to_github_repository
    github_team.add_team_repository(github_repository: github_repository)
  end

  def add_user_as_collaborator
    delete_github_repository_on_failure { github_repository.add_collaborator(github_user: github_user) }
  end

  def create_github_repository
    repo_description = "#{repo_name} created by Classroom for GitHub"
    github_repository = github_organization.create_repository(name: repo_name,
                                                              private: private?,
                                                              description: repo_description)
    self.github_repo_id = github_repository.id
  end

  def destroy_github_repository
    github_organization.delete_repository(github_repository: github_repository)
  end

  def delete_github_repository_on_failure
    yield
  rescue GitHub::Error
    silently_destroy_github_repository
    raise GitHub::Error, 'Assignment failed to be created'
  end

  def silently_destroy_github_repository
    destroy_github_repository
    true # Destroy ActiveRecord object even if we fail to delete the repository
  end

  def push_starter_code
    return true unless starter_code?

    starter_code_repository = GitHubRepository.new(id: starter_code_repo_id, access_token: creator.access_token)

    delete_github_repository_on_failure do
      github_repository.get_starter_code_from(source: starter_code_repository)
    end
  end
end
