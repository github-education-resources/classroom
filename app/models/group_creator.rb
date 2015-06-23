class GroupCreator
  def initialize(organization)
    @organization       = organization
    @organization_owner = @organization.owner
  end

  def create_group(group_title, grouping)
    group = Group.new(title: group_title, grouping: grouping)

    github_team          = GitHubTeam.create_team(@organization_owner, @organization.github_id, group.title)
    group.github_team_id = github_team.id

    group.save!
    group
  end
end
