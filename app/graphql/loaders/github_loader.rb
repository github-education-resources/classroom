require "graphql/remote_loader"

module GitHubClassroom
  class GitHubLoader < GraphQL::RemoteLoader::Loader
    def query(query_string, context:)
      parsed_query = GitHubClassroom::GitHubClient.parse(query_string)

      puts "** External GraphQL Query **"
      puts query_string.gsub(/\n/, " ")
      puts

      GitHubClassroom::GitHubClient.query(parsed_query, variables: {}, context: context)
    end
  end
end
