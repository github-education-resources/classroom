# frozen_string_literal: true

class Assignment
  class Creator
    attr_reader :assignment, :options

    class Result
      class Error < StandardError; end

      def self.success(assignment)
        new(:success, assignment: assignment)
      end

      def self.failed(assignment, error)
        new(:failed, assignment: assignment, error: error)
      end

      attr_reader :assignment, :error

      def initialize(status, assignment: nil, error: nil)
        @status     = status
        @assignment = assignment
        @error      = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    # Public: Create an Assignment.
    #
    # options - The Hash of attributes used to create the assignment.
    #
    # Returns a Assignment::Creator::Result.
    def self.perform(options:)
      new(options: options).perform
    end

    def initialize(options:)
      @options = options
    end

    def perform
      assignment = Assignment.new(@options)
      assignment.build_assignment_invitation
      assignment.save!
      assignment.deadline&.create_job

      send_create_assignment_statsd_events(assignment)
      Result.success(assignment)
    rescue ActiveRecord::RecordInvalid => error
      Result.failed(assignment, error.message)
    end

    private

    def send_create_assignment_statsd_events(assignment)
      GitHubClassroom.statsd.increment("exercise.create")
      GitHubClassroom.statsd.increment("deadline.create") if assignment.deadline
    end
  end
end
