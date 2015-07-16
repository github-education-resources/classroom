class AssignmentInvitationRedeemer < InvitationRedeemer
  def initialize(assignment)
    @assignment   = assignment
    @organization = assignment.organization
  end

  # Public
  #
  def redeem_for(invitee)
    repo_access_manager = RepoAccessManager.new(invitee, @organization)
    repo_access         = repo_access_manager.find_or_create_repo_access

    assignment_repo_manager = AssignmentRepoManager.new(@assignment, repo_access)
    assignment_repo         = assignment_repo_manager.find_or_create_assignment_repo

    full_repo_name = verify_github_presence(repo_access, assignment_repo)
    return full_repo_name unless @assignment.starter_code?

    push_starter_code(@assignment, assignment_repo)

    full_repo_name
  end
end
