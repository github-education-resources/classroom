# frozen_string_literal: true

require_relative "../loaders/github_loader"

class Types
  class User < GraphQL::Schema::Object
    # TODO: This should be:
    # User is one of
    # - The current_user
    # - A student of one organization the current_user is an admin of
    def self.authorized?(user, context)
      super
    end

    implements GraphQL::Relay::Node.interface

    global_id_field :id

    field :login, String, description: "The user's GitHub login.", null: false

    def login
      GitHubLoader.load_on_relay_node(object.github_node_id, "User", "login", context: context).then do |results|
        results.dig("data", "node", "login")
      end
    end

    field :github_url, String, description: "The user's GitHub profile URL.", null: true

    def github_url
      GitHubLoader.load_on_relay_node(object.github_node_id, "User", "url", context: context).then do |results|
        results.dig("data", "node", "url")
      end
    end

    field :avatar_url, String, description: "The user's GitHub avatar URL.", null: true

    def avatar_url
      GitHubLoader.load_on_relay_node(object.github_node_id, "User", "avatarUrl", context: context).then do |results|
        results.dig("data", "node", "avatar_url")
      end
    end
  end
end
