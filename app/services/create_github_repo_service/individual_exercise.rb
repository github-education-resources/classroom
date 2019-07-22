# frozen_string_literal: true

class CreateGitHubRepoService
  class IndividualExercise < Exercise
    def repos
      assignment.assignment_repos
    end

    def slug
      collaborator.github_user.login(use_cache: false)
    end

    def humanize
      "user"
    end

    def stat_prefix
      "exercise_repo"
    end
  end
end
