# frozen_string_literal: true

module GroupAssignmentRepoView
  class ShowView < SharedAssignmentRepoView
    delegate :github_team, to: :assignment_repo

    def github_avatar_url_for(student)
      super(student, 60)
    end

    def github_team_members
      assignment_repo.group.repo_accesses.map(&:user)
    end

    def github_team_url
      github_team.html_url
    end

    def members_text
      pluralize(github_team_members.length, "member")
    end
  end
end
