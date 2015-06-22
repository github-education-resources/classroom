class AssignmentInvitationRedeemer
  attr_reader :assignment, :invitee, :organization, :organization_owner

  def initialize(assignment, invitee)
    @assignment         = assignment
    @invitee            = invitee
    @organization       = assignment.organization
    @organization_owner = @organization.users.sample
  end

  def redeemed?
    repo_access_creator = RepoAccessCreator.new(@invitee, @organization)
    repo_access         = repo_access_creator.find_or_create_repo_access

    assignment_repo = find_or_create_assignment_repo(repo_access)

    full_repo_name  = @organization_owner.github_client.repository(assignment_repo.github_repo_id).full_name
    @organization_owner.github_client.team_repository?(repo_access.github_team_id, full_repo_name)
  end

  private

  def create_assignment_repo(repo_access, assignment_name)
    org_login = @organization_owner.github_client.organization(@organization.github_id).login

    repo = GitHubRepository.create_repository(@organization_owner,
                                              assignment_name,
                                              organization: org_login,
                                              team_id:      repo_access.github_team_id,
                                              private:      @assignment.private?)

    assignment_repo = AssignmentRepo.new(assignment: @assignment, github_repo_id: repo.id, repo_access: repo_access)

    assignment_repo.save!
    assignment_repo
  end

  def find_assignment_repo(repo_access)
    @assignment.assignment_repos.find_by(repo_access: repo_access)
  end

  def find_or_create_assignment_repo(repo_access)
    if (assignment_repo = find_assignment_repo(repo_access))
      assignment_repo
    else
      assignment_name = "#{@assignment.title}: #{@assignment.assignment_repos.count + 1}"
      create_assignment_repo(repo_access, assignment_name)
    end
  end
end
