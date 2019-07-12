# frozen_string_literal: true

class CreateGitHubRepoService
  class StatsSender
    attr_reader :entity
    def initialize(entity)
      @entity = entity
    end

    def default_failure
      GitHubClassroom.statsd.increment("#{root_prefix}.create.fail")
    end

    def default_success
      GitHubClassroom.statsd.increment("#{default_root_prefix}.create.success")
    end

    def timing(start_time)
      duration_in_millseconds = (Time.zone.now - start_time) * 1_000
      GitHubClassroom.statsd.timing("#{root_prefix}.create.time", duration_in_millseconds)
    end

    def repo_creation_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.fail")
    end

    def adding_collaborator_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.adding_collaborator.fail")
    end

    def importing_starter_code_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.importing_starter_code.fail")
    end

    def repo_creation_success
      GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.success")
    end

    def import_started
      GitHubClassroom.statsd.increment("#{root_prefix}.create.import.started")
    end

    private

    def default_root_prefix
      "exercise_repo"
    end

    def root_prefix
      if entity.user?
        default_root_prefix
      else
        "group_#{default_root_prefix}"
      end
    end
  end
end
