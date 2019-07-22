# frozen_string_literal: true

class CreateGitHubRepoService
  class Result
    class Error < StandardError
      def initialize(message, github_error_message = nil)
        message += " (#{github_error_message})" if github_error_message
        super(message)
      end
    end

    def self.success(repo, exercise)
      new(:success, repo: repo, exercise: exercise)
    end

    def self.failed(error, exercise)
      new(:failed, error: error, exercise: exercise)
    end

    def self.pending
      new(:pending)
    end

    attr_reader :error, :exercise, :status, :repo

    def initialize(status, exercise: nil, error: nil, repo: nil)
      @status          = status
      @exercise        = exercise
      @error           = error
      @repo            = repo
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
