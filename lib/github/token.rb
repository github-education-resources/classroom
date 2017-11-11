# frozen_string_literal: true

module GitHub
  module Token
    class << self
      SCOPE_TREE = {
        "repo" => {
          "repo:status"     => {},
          "repo_deployment" => {},
          "public_repo"     => {},
          "repo:invite"     => {}
        },
        "admin:org" => {
          "write:org" => {
            "read:org" => {}
          }
        },
        "admin:public_key" => {
          "write:public_key" => {
            "read:public_key" => {}
          }
        },
        "admin:repo_hook" => {
          "write:repo_hook" => {
            "read:repo_hook" => {}
          }
        },
        "admin:org_hook" => {},
        "gist" => {},
        "notifications" => {},
        "user" => {
          "read:user"   => {},
          "user:email"  => {},
          "user:follow" => {}
        },
        "delete_repo" => {},
        "admin:gpg_key" => {
          "write:gpg_key" => {
            "read:gpg_key" => {}
          }
        }
      }.freeze

      def scopes(token, client = nil)
        GitHub::Errors.with_error_handling do
          github_client = client.present? ? client : GitHubClassroom.github_client
          unexpanded_scopes = github_client.scopes(token, headers: GitHub::APIHeaders.no_cache_no_store)
          expand_scopes(unexpanded_scopes)
        end
      rescue GitHub::Forbidden
        []
      end

      # Having a scope like 'user' is actually read:user, user:email and user:follow
      # This method expands these collection scopes to make checking which scopes we have more simple
      def expand_scopes(scopes)
        scopes.map do |scope|
          [scope, descendents(scope)]
        end.flatten.uniq.sort
      end

      def descendents(scope, scope_tree = SCOPE_TREE)
        if scope_tree.key?(scope)
          return [] if scope_tree[scope].empty?
          top_level_recurse(scope, scope_tree)
        else
          mid_level_recurse(scope, scope_tree)
        end
      end

      def top_level_recurse(scope, scope_tree)
        [scope_tree[scope].keys, scope_tree[scope].keys.map { |key| descendents(key, scope_tree) }].flatten
      end

      def mid_level_recurse(scope, scope_tree)
        scope_tree.keys.map { |key| descendents(scope, scope_tree[key]) }.flatten
      end
    end
  end
end
