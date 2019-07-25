# frozen_string_literal: true

# Wrapper class over GitHubClassroom.statsd for creating repositories
# This enables us to add extra stats based on the progress of the repository being created
#
class CreateGitHubRepoService
  class StatsSender
    class InvalidStatError < StandardError; end

    attr_reader :exercise

    def initialize(exercise)
      @exercise = exercise
    end

    # Public: Method for reporting a stat to GitHubClassroom.statsd without exercise specific prefix,
    #         raises an InvalidStatError if appropriate method not found.
    #
    # stat - symbol for calling a stat.
    #
    # Returns the current value of increment from statsd.

    # default messages
    def report_default(stat)
      case stat
      when :success
        GitHubClassroom.statsd.increment("#{default_root_prefix}.create.success")
      when :failure
        GitHubClassroom.statsd.increment("#{default_root_prefix}.create.fail")
      else
        raise InvalidStatError, "#{stat} is an invalid stat, please use GitHubClassroom.statsd for sending custom stats"
      end
    end

    # Public: Method for reporting a stat to GitHubClassroom.statsd with exercise specific prefix,
    #         raises an InvalidStatError if appropriate method not found.
    #
    # stat - symbol for calling a stat.
    #
    # Returns the current value of increment from statsd.
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity
    def report_with_exercise_prefix(stat)
      case stat
      when :repository_creation_failed
        GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.fail")
      when :template_repository_creation_failed
        GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.with_templates.failed")
      when :collaborator_addition_failed
        GitHubClassroom.statsd.increment("#{root_prefix}.create.adding_collaborator.fail")
      when :starter_code_import_failed
        GitHubClassroom.statsd.increment("#{root_prefix}.create.importing_starter_code.fail")
      when :import_started
        GitHubClassroom.statsd.increment("#{root_prefix}.import.started")
      when :import_with_templates_started
        GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.with_templates.started")
      when :import_with_templates_success
        GitHubClassroom.statsd.increment("#{root_prefix}.create.repo.with_templates.success")
      else
        raise InvalidStatError, "#{stat} is an invalid stat, please use GitHubClassroom.statsd for sending custom stats"
      end
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity

    # Public: Sends the timing stat to statsd, timing is converted to millseconds
    #
    # start_time - Timestamp value of start time
    # rubocop:disable AbcSize
    def timing(start_time)
      duration_in_millseconds = (Time.zone.now - start_time) * 1_000
      if exercise.assignment.use_importer?
        GitHubClassroom.statsd.timing("#{root_prefix}.create.time.with_importer", duration_in_millseconds)
      elsif exercise.use_template_repos?
        GitHubClassroom.statsd.timing("#{root_prefix}.create.time.with_templates", duration_in_millseconds)
      else
        GitHubClassroom.statsd.timing("#{root_prefix}.create.time", duration_in_millseconds)
      end
    end
    # rubocop:enable AbcSize

    private

    # Internal: default prefix on Datadog for repository creation
    #
    def default_root_prefix
      "exercise_repo"
    end

    # Internal: get the root prefix for an exercise
    #
    def root_prefix
      exercise.stat_prefix
    end
  end
end
