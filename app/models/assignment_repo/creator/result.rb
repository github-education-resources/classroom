# frozen_string_literal: true

class AssignmentRepo
  class Creator
    class Result
      class Error < StandardError
        def initialize(message, github_error_message = nil)
          message += " (#{github_error_message})" if github_error_message
          super(message)
        end
      end

      def self.success(assignment_repo)
        new(:success, assignment_repo: assignment_repo)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      def self.pending
        new(:pending)
      end

      attr_reader :error, :assignment_repo, :status

      def initialize(status, assignment_repo: nil, error: nil)
        @status          = status
        @assignment_repo = assignment_repo
        @error           = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end

      def pending?
        @status == :pending
      end
    end
  end
end
