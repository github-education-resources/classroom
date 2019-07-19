# frozen_string_literal: true

class CreateGitHubRepoService
  module Broadcaster
    MESSAGES = {
      repository_creation_complete: "Your GitHub repository was created.",
      import_ongoing: "Your GitHub repository is importing starter code.",
      create_repo: "Creating GitHub repository.",
      importing_starter_code: "Importing starter code."
    }.freeze

    def self.call(exercise, message, message_type, repo_url = nil)
      message_hash = build_message(exercise, message, message_type, repo_url)
      channel = build_channel(exercise)
      ActionCable.server.broadcast(channel, message_hash)
    end

    def self.build_channel(exercise)
      channel_class =
        if exercise.user?
          RepositoryCreationStatusChannel
        else
          GroupRepositoryCreationStatusChannel
        end
      channel_class.channel(channel_hash(exercise))
    end

    def self.build_message(exercise, message, message_type, repo_url = nil)
      {}.tap do |msg|
        msg[:status] = exercise.status
        msg[:repo_url] = repo_url if repo_url.present?
        msg[message_type] = MESSAGES.fetch(message) { message }
      end
    end

    def self.channel_hash(exercise)
      {}.tap do |msg|
        msg["#{exercise.humanize}_id".to_sym] = exercise.collaborator.id
        msg["#{exercise.assignment_type}_id".to_sym] = exercise.assignment.id
      end
    end
  end
end
