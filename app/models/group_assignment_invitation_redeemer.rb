class GroupAssignmentInvitationRedeemer < InvitationRedeemer
  def initialize(group_assignment, group, group_title)
    @group              = group
    @group_assignment   = group_assignment
    @group_title        = group_title
    @organization       = group_assignment.organization
  end

  # Public
  #
  def redeem_for(invitee)
    repo_access           = setup_repo_access(invitee)
    group                 = setup_group(repo_access)
    group_assignment_repo = setup_group_assignment_repo(repo_access, group)

    full_repo_name = verify_github_presence(repo_access, group_assignment_repo)
    return full_repo_name unless @group_assignment.starter_code?

    push_starter_code(@group_assignment, group_assignment_repo)

    full_repo_name
  end

  # Internal
  #
  def find_group(repo_access)
    @group_assignment.grouping.groups.each do |group|
      return group if group.repo_accesses.find_by(id: repo_access.id)
    end

    return @group unless @group.nil?
  end

  # Internal
  #
  def setup_group(repo_access)
    group_manager = GroupManager.new(@group_assignment, @group)
    group         = find_group(repo_access) || group_manager.create_group(@group_title)

    group_manager.group = group
    group_manager.add_repo_access_to_group(repo_access)

    group
  end

  # Internal
  #
  def setup_group_assignment_repo(repo_access, group)
    group_assignment_repo_manager = GroupAssignmentRepoManager.new(@group_assignment, group, repo_access)
    group_assignment_repo         = group_assignment_repo_manager.find_or_create_group_assignment_repo

    group_assignment_repo_manager.add_repo_access_to_assignment_repo

    group_assignment_repo
  end

  # Internal
  #
  def setup_repo_access(invitee)
    repo_access_manager = RepoAccessManager.new(invitee, @organization)
    repo_access_manager.find_or_create_repo_access
  end
end
