class GroupAssignmentInvitationRedeemer
  def initialize(group_assignment, invitee, group = {})
    @group_assignment   = group_assignment
    @group_id           = group[:id]
    @group_title        = group[:title]
    @invitee            = invitee
    @organization       = group_assignment.organization
    @organization_owner = @organization.owner
  end

  def redeemed?
    repo_access = find_or_create_repo_access
    group       = find_or_create_group

    add_repo_access_to_group(group, repo_access)

    group_assignment_repo = find_or_create_group_assignment_repo(repo_access, group)

    validate_github_presence(group_assignment_repo, repo_access)
  end

  private

  def add_repo_access_to_group(group, repo_access)
    group.repo_accesses << repo_access

    github_team = GitHubTeam.new(@organization_owner, group.github_team_id, nil)
    github_team.add_user_to_team(@invitee)
  end

  def create_group_assignment_repo(repo_access, group, group_assignment_name)
    repo = GitHubRepository.create_repository(@organization_owner,
                                              group_assignment_name,
                                              team_id:      repo_access.github_team_id,
                                              private:      @group_assignment.private?,
                                              organization: @organization.github_login)

    group_assignment_repo = GroupAssignmentRepo.new(github_repo_id:   repo.id,
                                                    group_assignment: @group_assignment,
                                                    group:            group)

    group_assignment_repo.save!
    group_assignment_repo
  end

  def find_group_assignment_repo(group)
    @group_assignment.group_assignment_repos.find_by(group: group)
  end

  def find_or_create_group_assignment_repo(repo_access, group)
    if (group_assignment_repo = find_group_assignment_repo(group))
      group_assignment_repo
    else
      group_assignment_name = "#{@group_assignment.title}: #{group.title}"
      create_group_assignment_repo(repo_access, group, group_assignment_name)
    end
  end

  def find_or_create_group
    if (group = @group_assignment.groups.find_by(id: @group_id))
      group
    else
      group_creator = GroupCreator.new(@organization)
      group_creator.create_group(@group_title, @group_assignment.grouping)
    end
  end

  def find_or_create_repo_access
    repo_access_creator = RepoAccessCreator.new(@invitee, @organization)
    repo_access_creator.find_or_create_repo_access
  end

  def validate_github_presence(group_assignment_repo, repo_access)
    full_repo_name  = @organization_owner.github_client.repository(group_assignment_repo.github_repo_id).full_name
    @organization_owner.github_client.team_repository?(repo_access.github_team_id, full_repo_name)
  end
end
