# frozen_string_literal: true
module GitHub
  module Token
    class << self
      def scopes(token, client = nil)
        GitHub::Errors.with_error_handling do
          github_client = client.present? ? client : GitHubClassroom.github_client
          github_client.scopes(token, headers: GitHub::APIHeaders.no_cache_no_store)
        end
      rescue GitHub::Forbidden
        []
      end
    end
  end
end
