class InvitationRedeemer
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
