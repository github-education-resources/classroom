class GitHubTeam
  include GitHub

  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def add_to_team(new_user_github_login)
    with_error_handling do
      @client.add_team_membership(@id, new_user_github_login)
    end
  end

  # Public
  #
  def team_repository?(full_repo_name)
    with_error_handling do
      @client.team_repository?(@id, full_repo_name)
    end
  end
end
