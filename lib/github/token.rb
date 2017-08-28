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

      # Note that this will only work for a scope that is _at MAX_
      # three children deep.
      #
      # Since I don't think OAuth scopes will ever get that deep YOLO
      # - <3 @tarebyte
      def descendents(scope, scope_tree = SCOPE_TREE)
        if parent_scope?(scope, scope_tree)
          return scope_tree[scope].keys.map do |child|
            [child, descendents(child)]
          end.flatten
        else
          parent_scopes(scope_tree).each do |top|
            return scope_tree[top][scope].keys if scope_tree[top].key?(scope)
          end
        end

        []
      end

      private

      def parent_scopes(scope_tree)
        return @parent_scopes if defined?(@parent_scopes)
        @parent_scopes = scope_tree.keys
      end

      def parent_scope?(scope, scope_tree)
        !scope_tree[scope].nil?
      end
    end
  end
end
