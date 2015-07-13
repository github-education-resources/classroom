class InvitationRedeemer
  # Internal
  #
  def push_starter_code(assignment, assignment_repo)
    creator_github_client = assignment.creator.github_client
    assignment_repository = GitHubRepository.new(creator_github_client, assignment_repo.github_repo_id)

    return if assignment_repository.branches.present?

    starter_code_repository = GitHubRepository.new(creator_github_client, assignment.starter_code_repo_id)
    starter_code_repository.push_to(assignment_repository.full_name)
  end

  # Internal
  #
  def verify_github_presence(repo_access, assignment_repo)
    github_client = repo_access.organization.fetch_owner.github_client

    github_repository = GitHubRepository.new(github_client, assignment_repo.github_repo_id)
    full_repo_name    = github_repository.full_name

    github_team = GitHubTeam.new(github_client, repo_access.github_team_id)
    full_repo_name if github_team.team_repository?(full_repo_name)
  end
end
