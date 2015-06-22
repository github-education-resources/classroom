class RepoAccessCreator
  def initialize(user, organization)
    @user               = user
    @organization       = organization
    @organization_owner = @organization.users.sample
  end

  def find_or_create_repo_access
    if (repo_access = find_repo_access)
      repo_access
    else
      team_name = "Team: #{@organization.repo_accesses.count + 1}"
      create_repo_access(team_name)
    end
  end

  private

  def create_repo_access(team_name)
    github_team = GitHubTeam.create_team(@organization_owner, @organization.github_id, team_name)

    github_team.add_user_to_team(@user)

    repo_access = RepoAccess.new(github_team_id: github_team.id, organization: @organization, user: @user)

    repo_access.save!
    repo_access
  end

  def find_repo_access
    @user.repo_accesses.find_by(organization: @organization)
  end
end
