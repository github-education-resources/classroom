class GitHubTeam < GitHubResource
  def add_team_membership(github_user:)
    GitHub::Errors.with_error_handling do
      client.add_team_membership(id, github_user.login)
    end
  end

  def remove_team_membership(github_user:)
    GitHub::Errors.with_error_handling do
      client.remove_team_membership(id, github_user.login)
    end
  end

  def add_team_repository(github_repository:)
    GitHub::Errors.with_error_handling do
      unless client.add_team_repository(id, github_repository.full_name)
        raise GitHub::Error, 'Could not add team to the GitHub repository'
      end
    end
  end

  def team(**options)
    GitHub::Errors.with_error_handling { client.team(id, options) }
  end

  def team_repository?(github_repository:)
    GitHub::Errors.with_error_handling do
      client.team_repository?(id, github_repository.full_name)
    end
  end

  def disabled?
    return @disabled if defined?(@disabled)
    @disabled = (slug == 'ghost')
  end

  # Internal
  def github_attributes
    %w(name slug)
  end
end
