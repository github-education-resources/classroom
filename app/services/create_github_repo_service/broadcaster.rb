# frozen_string_literal: true

class CreateGitHubRepoService
  class Broadcaster
    MESSAGES = {
      repository_creation_complete: "Your GitHub repository was created.",
      import_ongoing: "Your GitHub repository is importing starter code.",
      create_repo: "Creating GitHub repository.",
      importing_starter_code: "Importing starter code."
    }.freeze

    attr_reader :exercise, :message, :message_type, :repo_url

    def self.call(exercise, message, message_type, repo_url = nil)
      new(exercise, message, message_type, repo_url).call
    end

    def initialize(exercise, message, message_type, repo_url = nil)
      @exercise = exercise
      @message = message
      @message_type = message_type
      @repo_url = repo_url
    end

    def call
      ActionCable.server.broadcast(channel, message_hash)
    end

    private

    def channel
      channel_class.channel(channel_hash)
    end

    def channel_class
      if exercise.user?
        RepositoryCreationStatusChannel
      else
        GroupRepositoryCreationStatusChannel
      end
    end

    def message_hash
      {}.tap do |msg|
        msg[:status] = exercise.status
        msg[:repo_url] = repo_url if repo_url.present?
        msg[message_type] = MESSAGES.fetch(message) { message }
      end
    end

    def channel_hash
      {}.tap do |msg|
        msg["#{exercise.humanize}_id".to_sym] = exercise.collaborator.id
        msg["#{exercise.assignment_type}_id".to_sym] = exercise.assignment.id
      end
    end
  end
end
