class CollabMigration
  attr_accessor :repo_access

  def initialize(repo_access)
    @repo_access = repo_access
  end

  def migrate
    @repo_access.assignment_repos.each { |assignment_repo| add_user_as_collaborator(assignment_repo) }

    return unless @repo_access.github_team_id.present?

    begin
      github_organization.delete_team(github_team: @repo_access.github_team)
      @repo_access.update_attributes(github_team_id: nil)
    rescue Octokit::Unauthorized => e
      Rails.logger.info e
    end
  end

  protected

  def add_user_as_collaborator(assignment_repo)
    assignment_repo.github_repository.add_collaborator(github_user: github_user)
  end

  def github_organization
    @github_organization ||= organization.github_organization
  end

  def github_user
    @github_user ||= @repo_access.github_user
  end

  def organization
    @organization ||= @repo_access.organization
  end
end
