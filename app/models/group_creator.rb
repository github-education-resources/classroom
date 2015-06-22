class GroupCreator
  attr_reader :group

  def initialize(user, organization)
    @user               = user
    @organization       = organization
    @organization_owner = @organization.users.sample
  end

  def create_group(new_group_options)
    repo_access_creator = RepoAccessCreator.new(@user, @organization)
    repo_access         = repo_access_creator.find_or_create_repo_access

    group = Group.new(new_group_options)
    group.repo_accesses << repo_access

    github_team = GitHubTeam.create_team(@organization_owner, @organization.github_id, group.title)

    github_team.add_user_to_team(@user)
    group.github_team_id = github_team.id

    group.save!
    group
  end
end
