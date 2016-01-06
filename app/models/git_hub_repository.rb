class GitHubRepository
  include GitHub

  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def add_collaborator(collaborator)
    with_error_handling do
      @client.add_collaborator(@id, collaborator)
    end
  end

  # Public
  #
  def full_name
    with_error_handling { @client.repository(@id).full_name }
  end

  # Public
  #
  def get_starter_code_from(source)
    with_error_handling do
      @client.put(
        "/repositories/#{@id}/import",
        headers: import_preview_header,
        'vcs': 'git',
        'vcs_url': "https://github.com/#{source.full_name}",
        'vcs_username': @client.login,
        'vcs_password': @client.access_token
      )
    end
  end

  # Public
  #
  def repository(full_repo_name = nil)
    with_error_handling do
      @client.repository(full_repo_name || @id)
    end
  end
end
