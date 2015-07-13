class GitHubRepository
  include GitHub

  attr_reader :full_name, :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def branches
    with_error_handling { @client.branches(full_name) }
  end

  # Public
  #
  def full_name
    @full_name ||= with_error_handling { @client.repository(@id).full_name }
  end

  # Public
  #
  def push_to(destination)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git clone --bare https://#{@client.access_token}@github.com/#{full_name}.git")
        Dir.chdir("#{full_name.split('/').last}.git") do
          system("git push --mirror https://#{@client.access_token}@github.com/#{destination}.git")
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
