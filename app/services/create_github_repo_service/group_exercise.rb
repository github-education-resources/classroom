# frozen_string_literal: true

class CreateGitHubRepoService
  class GroupExercise < Exercise
    def repos
      assignment.group_assignment_repos
    end

    def slug
      collaborator.github_team.slug_no_cache
    end

    def humanize
      "group"
    end

    def stat_prefix
      "group_exercise_repo"
    end
  end
end
