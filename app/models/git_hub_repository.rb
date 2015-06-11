class GitHubRepository
  attr_reader :id, :name

  def initialize(id, name, url)
    @id   = id
    @name = name
    @url  = url
  end

  def self.create_repository_for_team(org_owner, organization, team_id, repo_name)
    github_organization = org_owner.github_client.organization(organization.github_id)
    options             = github_repo_options(github_organization, team_id)

    if (repo = org_owner.github_client.create_repository(repo_name, options))
      GitHubRepository.new(repo.id, repo.name, repo.html_url)
    else
      NullGitHubRepository.new
    end
  end

  def self.github_repo_options(github_organization, team_id)
    {
      private:       true,
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  github_organization.login,
      team_id:       team_id
    }
  end
end
