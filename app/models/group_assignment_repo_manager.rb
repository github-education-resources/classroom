class GroupAssignmentRepoManager
  attr_accessor :group_assignment_repo

  def initialize(group_assignment, group, repo_access)
    @group_assignment   = group_assignment
    @group              = group
    @organization       = group_assignment.organization
    @repo_access        = repo_access
    @github_client      = @organization.fetch_owner.github_client
  end

  # Public
  #
  def add_repo_access_to_assignment_repo
    github_repository = GitHubRepository.new(@github_client, @group_assignment_repo.github_repo_id)
    github_team       = GitHubTeam.new(@github_client, @repo_access.github_team_id)

    full_repo_name    = github_repository.full_name

    return true if github_team.team_repository?(full_repo_name)

    github_team.add_team_repository(full_repo_name)
  end

  # Public
  #
  def find_or_create_group_assignment_repo
    @group_assignment_repo = find_group_assignment_repo || create_group_assignment_repo
  end

  # Internal
  #
  def create_group_assignment_repo
    github_organization = GitHubOrganization.new(@github_client, @organization.github_id)
    github_repository   = github_organization.create_repository(group_assignment_title,
                                                                team_id: @repo_access.github_team_id,
                                                                private: @group_assignment.private?,
                                                                description: group_assignment_description)

    GroupAssignmentRepo.create!(group_assignment: @group_assignment,
                                github_repo_id:   github_repository.id,
                                group:            @group)
  end

  # Internal
  #
  def find_group_assignment_repo
    @group_assignment.group_assignment_repos.find_by(group: @group)
  end

  # Internal
  #
  def group_assignment_description
    "#{@group_assignment.title} created by GitHub Classroom for #{@group.title}"
  end

  # Internal
  #
  def group_assignment_title
    "#{@group_assignment.title} #{@group.title}"
  end
end
