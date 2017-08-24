# frozen_string_literal: true

module GitHub
  module Token
    class << self
      EXPANSIONS = {
        "repo"             => { "repo:status" => {}, "repo_deployment" => {}, "public_repo" => {}, "repo:invite" => {} },
        "admin:org"        => { "write:org" => { "read:org" => {} } },
        "admin:public_key" => { "write:public_key" => { "read:public_key" => {} } },
        "admin:repo_hook"  => { "write:repo_hook" => { "read:repo_hook" => {} } },
        "user"             => { "read:user" => {}, "user:email" => {}, "user:follow" => {} },
        "admin:gpg_key"    => { "write:gpg_key" => { "read:gpg_key" => {} } }
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

      def scopes_match?(scopes, other_scopes)
        expand_scopes(scopes) == expand_scopes(other_scopes)
      end

      # Having a scope like 'user' is actually read:user, user:email and user:follow
      # This method expands these collection scopes to make checking which scopes we have more simple
      def expand_scopes(scopes)
        all = []
        scopes.each do |scope|
          all << scope
          all << descendents(scope)
        end

        all.flatten
      end

      def descendents(scope)
        if EXPANSIONS[scope].nil?
          EXPANSIONS.keys.each do |top|
            if EXPANSIONS[top].key?(scope)
              return EXPANSIONS[top][scope].keys
            end
          end
        else
          summation = []
          EXPANSIONS[scope].keys.each do |child|
            summation << child
            summation << descendents(child)
          end

          return summation.flatten
        end

        []
      end
    end
  end
end
