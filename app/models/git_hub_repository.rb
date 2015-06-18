class GitHubRepository
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def self.create_repository(org_owner, repo_name, user_repo_options)
    repo_options = github_repo_default_options.merge(user_repo_options)

    if (repo = org_owner.github_client.create_repository(repo_name, repo_options))
      GitHubRepository.new(repo.id)
    else
      NullGitHubRepository.new
    end
  end

  def self.github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true
    }
  end
end
