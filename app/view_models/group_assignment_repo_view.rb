# frozen_string_literal: true

class GroupAssignmentRepoView < SharedAssignmentRepoView
  def avatar_url_for(student)
    super(student, 60)
  end

  def team_members
    assignment_repo.group.repo_accesses.map(&:user)
  end

  def team_url
    team.html_url
  end

  def team
    assignment_repo.github_team
  end

  def members_text
    pluralize(team_members.length, 'member')
  end
end
