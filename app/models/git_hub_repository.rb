class GitHubRepository
  include GitHub

  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def full_name
    with_error_handling { @client.repository(@id).full_name }
  end
end
