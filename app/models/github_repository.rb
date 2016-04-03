class GitHubRepository < GitHubResource
  def add_collaborator(github_user:)
    GitHub::Errors.with_error_handling do
      client.add_collaborator(id, github_user.login)
    end
  end

  def disabled?
    return @disabled if defined?(@disabled)
    @disabled = full_name == 'Deleted repository'
  end

  def get_starter_code_from(source:)
    GitHub::Errors.with_error_handling do
      credentials = { vcs_username: client.login, vcs_password: client.access_token }
      client.start_source_import(id, 'git', "https://github.com/#{source.full_name}", credentials)
    end
  end

  def repository(full_name: nil)
    GitHub::Errors.with_error_handling do
      client.repository(full_name || id)
    end
  end

  private

  def github_attributes
    %w(full_name html_url)
  end
end
