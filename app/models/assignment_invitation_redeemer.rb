class AssignmentInvitationRedeemer
  def initialize(assignment, invitee)
    @assignment         = assignment
    @invitee            = invitee
    @organization       = assignment.organization
    @organization_owner = @organization.fetch_owner
  end

  # Public
  #
  def redeem
    repo_access_manager = RepoAccessManager.new(@invitee, @organization)
    repo_access         = repo_access_manager.find_or_create_repo_access(team_name)

    assignment_repo_manager = AssignmentRepoManager.new(@assignment, repo_access)
    assignment_repo = assignment_repo_manager.find_or_create_assignment_repo(assignment_title)

    verify_github_presence(repo_access, assignment_repo)
  end

  # Internal
  #
  def verify_github_presence(repo_access, assignment_repo)
    github_repository = GitHubRepository.new(@organization_owner.github_client, assignment_repo.github_repo_id)
    full_repo_name    = github_repository.full_name

    github_team = GitHubTeam.new(@organization_owner.github_client, repo_access.github_team_id)
    github_team.team_repository?(full_repo_name)

    "https://github.com/#{full_repo_name}"
  end

  # Internal
  #
  def assignment_title
    "GHClassrooom Assignment #{@assignment.title} #{@assignment.assignment_repos.count + 1}"
  end

  # Internal
  #
  def team_name
    "GHClassroom Student Team #{@organization.repo_accesses.count + 1}"
  end
end
