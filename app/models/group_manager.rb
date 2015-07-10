class GroupManager
  attr_accessor :group

  def initialize(group_assignment, group = nil)
    @group_assignment = group_assignment
    @group            = group
    @organization     = group_assignment.organization
    @github_client    = @organization.fetch_owner.github_client
  end

  # Public
  #
  def add_repo_access_to_group(repo_access)
    return true if @group.repo_accesses.find_by(id: repo_access.id)

    github_team = GitHubTeam.new(@github_client, group.github_team_id)
    github_team.add_team_membership(repo_access.user.github_login)

    @group.repo_accesses << repo_access
    @group.save!
  end

  # Internal
  #
  def create_group(group_team_name)
    github_organization = GitHubOrganization.new(@github_client, @organization.github_id)
    github_team         = github_organization.create_team(group_team_name)

    @group = Group.create!(title: group_team_name, github_team_id: github_team.id, grouping: @group_assignment.grouping)
  end
end
