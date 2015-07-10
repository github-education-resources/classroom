class RepoAccessManager
  def initialize(user, organization)
    @organization       = organization
    @organization_owner = organization.fetch_owner
    @user               = user
  end

  # Public
  #
  def find_or_create_repo_access
    find_repo_access || create_repo_access
  end

  # Internal
  #
  def find_repo_access
    @user.repo_accesses.find_by(organization: @organization)
  end

  # Internal
  #
  def create_repo_access
    github_organization = GitHubOrganization.new(@organization_owner.github_client, @organization.github_id)
    github_team         = github_organization.create_team(team_name)

    github_team.add_team_membership(@user.github_login)

    RepoAccess.create!(user: @user, organization: @organization, github_team_id: github_team.id)
  end

  # Internal
  #
  def team_name
    "Team #{@organization.repo_accesses.count + 1}"
  end
end
