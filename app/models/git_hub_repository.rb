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
      @client.start_source_import(@id, 'git', "https://github.com/#{source.full_name}")
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
