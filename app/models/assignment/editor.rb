# frozen_string_literal: true
class Assignment
  class Editor
    attr_reader :assignment, :options

    class Result
      class Error < StandardError; end

      def self.success(assignment)
        new(:success, assignment: assignment)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :assignment

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

    # Public: Edit an Assignment.
    #
    # assignment - The Assignment that is being edited.
    # options    - The Hash of attributes being edited on the assignment.
    #
    # Returns a Assignment::Editor::Result.
    def self.perform(assignment:, options:)
      new(assignment: assignment, options: options).perform
    end

    def initialize(assignment:, options:)
      @assignment = assignment
      @options    = options
    end

    def perform
      @assignment.update_attributes(@options)
      raise Result::Error @assignment.errors unless @assignment.valid?

      time = Time.zone.now.to_i
      @assignment.previous_changes.each do |attribute, change|
        update_attribute_for_all_assignment_repos(time: time, attribute: attribute, change: change)
      end
    rescue Result::Error => err
      Result.failed(err.message)
    end

    private

    def update_attribute_for_all_assignment_repos(time:, attribute:, change:)
      case attribute
      when 'students_are_repo_admins'
        Assignment::RepositoryAdministrationJob.perform_later(@assignment, time: time, change: change)
      end
    end
  end
end
