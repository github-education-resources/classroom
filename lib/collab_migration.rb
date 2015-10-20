class CollabMigration
  attr_accessor :repo_access

  def initialize(repo_access)
    @repo_access = repo_access
  end

  def migrate
    # For each assignment_repo add the user as a collaborator
    @repo_access.assignment_repos.each do |assignment_repo|
      repository = GitHubRepository.new(organization.github_client, assignment_repo.github_repo_id)
      repository.add_collaborator(github_user.login)
    end

    # delete the github team if present
    if @repo_access.github_team_id.present?
      github_organization.delete_team(@repo_access.github_team_id)

      @repo_access.github_team_id = nil
      @repo_access.save
    end
  end

  protected

  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end

  def github_user
    @github_user ||= GitHubUser.new(@repo_access.user.github_client, @repo_access.user.uid)
  end

  def organization
    @organization ||= @repo_access.organization
  end
end
