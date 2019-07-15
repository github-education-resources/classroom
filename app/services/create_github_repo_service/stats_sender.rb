# frozen_string_literal: true

# Wrapper class over GitHubClassroom.statsd for creating repositories
# This enables us to add extra stats based on the progress of the repository being created
#
class CreateGitHubRepoService
  class StatsSender
    class InvalidStatError < StandardError; end
    attr_reader :entity
    def initialize(entity)
      @entity = entity
    end

    # Public: Method for reporting a stat to GitHubClassroom.statsd,
    #         raises an InvalidStatError if appropriate method not found.
    #
    # stat - symbol for calling a stat.
    #
    # Returns the current value of increment from statsd.
    def report(stat)
      send(stat)
    rescue NoMethodError
      raise InvalidStatError, "#{stat} is not a valid stat, please use GitHubClassroom.statsd for sending custom stats"
    end

    # Public: Sends the timing stat to statsd, timing is converted to millseconds
    #
    # start_time - Timestamp value of start time
    def timing(start_time)
      duration_in_millseconds = (Time.zone.now - start_time) * 1_000
      GitHubClassroom.statsd.timing("#{root_prefix}.create.time", duration_in_millseconds)
    end

    protected

    # default messages
    def failure
      GitHubClassroom.statsd.increment("#{default_root_prefix}.create.fail")
    end

    def success
      GitHubClassroom.statsd.increment("#{default_root_prefix}.create.success")
    end

    # exercise based messages
    def repo_creation_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.fail")
    end

    def adding_collaborator_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.adding_collaborator.fail")
    end

    def importing_starter_code_failed
      GitHubClassroom.statsd.increment("#{root_prefix}.create.importing_starter_code.fail")
    end

    def import_started
      GitHubClassroom.statsd.increment("#{root_prefix}.import.started")
    end

    private

    def default_root_prefix
      "exercise_repo"
    end

    def root_prefix
      entity.stat_prefix
    end
  end
end
