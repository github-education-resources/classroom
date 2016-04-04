class GitHubOrganization < GitHubResource
  def add_membership(github_user:)
    return if member?(github_user: github_user)

    GitHub::Errors.with_error_handling do
      client.update_organization_membership(login, user: github_user.login)
    end
  end

  def create_repository(name:, **options)
    repo_options = github_repo_default_options.merge(options)

    repo = GitHub::Errors.with_error_handling do
      client.create_repository(name, repo_options)
    end

    GitHubRepository.new(id: repo.id, access_token: access_token)
  end

  def delete_repository(github_repository:)
    client.delete_repository(github_repository.id)
  end

  def create_team(name:)
    github_team = GitHub::Errors.with_error_handling do
      client.create_team(
        id,
        description: "#{name} created by Classroom for GitHub",
        name:        name,
        permission: 'push'
      )
    end

    GitHubTeam.new(id: github_team.id, access_token: access_token)
  end

  def delete_team(github_team:)
    client.delete_team(github_team.id)
  end

  def disabled?
    return @disabled if defined?(@disabled)
    @disabled = (login == 'ghost')
  end

  def member?(github_user:)
    GitHub::Errors.with_error_handling { client.organization_member?(id, github_user.login) }
  end

  def organization(**options)
    @organization ||= client.organization(id, options)
  end

  def plan
    GitHub::Errors.with_error_handling do
      if organization.owned_private_repos.present? && organization.plan.present?
        { owned_private_repos: organization.owned_private_repos, private_repos: organization.plan.private_repos }
      else
        raise GitHub::Error, 'Cannot retrieve this organizations repo plan, please reauthenticate your token.'
      end
    end
  end

  def remove_member(member:)
    begin
      return if member.active_admin?(github_organization: self)
    rescue GitHub::NotFound
      return
    end

    GitHub::Errors.with_error_handling do
      client.remove_organization_member(id, member.login)
    end
  end

  # Internal
  def github_attributes
    %w(login avatar_url html_url name)
  end

  private

  def github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  id
    }
  end
end
