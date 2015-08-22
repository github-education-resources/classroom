class GitHubOrganization
  include GitHub

  def initialize(client, id)
    @client    = client
    @id        = id
  end

  # Public
  #
  def accept_membership
    with_error_handling do
      @client.update_organization_membership(login, state: 'active')
    end
  end

  # Public
  #
  def admin?(user_github_login)
    with_error_handling do
      membership = @client.organization_membership(login, user: user_github_login)
      membership.role == 'admin' && membership.state == 'active'
    end
  end

  # Public
  #
  def create_repository(repo_name, users_repo_options = {})
    repo_options = github_repo_default_options.merge(users_repo_options)

    repo = with_error_handling do
      @client.create_repository(repo_name, repo_options)
    end

    GitHubRepository.new(@client, repo.id)
  end

  # Public
  #
  def delete_repository(repo_id)
    @client.delete_repository(repo_id)
  end

  # Public
  #
  def create_team(team_name)
    github_team = with_error_handling do
      @client.create_team(@id,
                          description: "#{team_name} created by GitHub Classroom",
                          name: team_name,
                          permission: 'push')
    end

    GitHubTeam.new(@client, github_team.id)
  end

  # Public
  #
  def delete_team(team_id)
    @client.delete_team(team_id)
  end

  # Public
  #
  def login
    with_error_handling { @client.organization(@id).login }
  end

  # Public
  #
  def organization
    with_error_handling { @client.organization(@id) }
  end

  # Public
  #
  def organization_members(options = {})
    with_error_handling { @client.organization_members(@id, options) }
  end

  private

  # Internal
  #
  def github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  @id
    }
  end
end
