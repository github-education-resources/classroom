# frozen_string_literal: true

class GroupAssignmentRepoView < ViewModel
  attr_reader :assignment_repo

  def repo_url
    @repo_url ||= github_repo.html_url
  end

  def github_repo
    assignment_repo.github_repository
  end

  def team_members
    @team_members ||= assignment_repo.group.repo_accesses.map(&:user)
  end

  def team_url
    @team_url ||= team.html_url
  end

  def team_name
    @team_name ||= team.name
  end

  def team
    assignment_repo.github_team
  end

  def number_of_commits
    branch = github_repo.default_branch
    @number_of_commits ||= github_repo.commits(branch).length
  end

  def disabled?
    assignment_repo.disabled?
  end
end
