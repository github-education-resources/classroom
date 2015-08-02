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

  # Public
  #
  def get_starter_code_from(source)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git clone --bare https://#{@client.access_token}@github.com/#{source}.git")
        Dir.chdir("#{source.split('/').last}.git") do
          system("git push --mirror https://#{@client.access_token}@github.com/#{full_name}.git")
        end
      end
    end
  end

  # Public
  #
  def repository(full_repo_name = nil)
    with_error_handling do
      repo = @client.repository(full_repo_name)
      GitHubRepository.new(@client, repo.id)
    end
  end
end
