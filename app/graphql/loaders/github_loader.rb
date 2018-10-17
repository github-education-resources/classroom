# frozen_string_literal: true

require "graphql/remote_loader"

class GitHubLoader < GraphQL::RemoteLoader::Loader
  def query(query_string, context:)
    parsed_query = GitHubClassroom::GitHubClient.parse(query_string)

    # TODO: Properly log a few things here:
    # - The external query
    # - The parse time
    # - The query time
    GitHubClassroom::GitHubClient.query(parsed_query, variables: {}, context: context)
  end
end
