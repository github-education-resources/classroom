# frozen_string_literal: true

class CreateGitHubRepoService
  class Result
    class Error < StandardError
      def initialize(message, github_error_message = nil)
        message += " (#{github_error_message})" if github_error_message
        super(message)
      end
    end

    def self.success(repo, entity)
      new(:success, repo: repo, entity: entity)
    end

    def self.failed(error, entity)
      new(:failed, error: error, entity: entity)
    end

    def self.pending
      new(:pending)
    end

    attr_reader :error, :entity, :status, :repo

    def initialize(status, entity: nil, error: nil, repo: nil)
      @status          = status
      @entity          = entity
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