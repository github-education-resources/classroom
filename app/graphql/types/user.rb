require_relative "../loaders/github_loader"

def user_query(obj, fields)
  <<-GRAPHQL
    node(id: "#{obj.github_global_relay_id}"){
      ... on User {
        #{fields}
      }
    }
  GRAPHQL
end

class Types::User < GraphQL::Schema::Object
  field :login, String, description: "The user's GitHub login.", null: false

  def login
    GitHubClassroom::GitHubLoader.load(user_query(object, "login"), context: context).then do |results|
      results.dig("data", "node", "login")
    end
  end

  field :github_url, String, description: "The user's GitHub profile URL.", null: true

  def github_url
    GitHubClassroom::GitHubLoader.load(user_query(object, "url"), context: context).then do |results|
      results.dig("data", "node", "url")
    end
  end

  field :avatar_url, String, description: "The user's GitHub avatar URL.", null: true

  def avatar_url
    GitHubClassroom::GitHubLoader.load(user_query(object, "avatarUrl"), context: context).then do |results|
      results.dig("data", "node", "avatar_url")
    end
  end
end
