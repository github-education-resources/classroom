require_relative "../loaders/github_loader"
require "graphql"

class Types
  class QueryType < GraphQL::Schema::Object
    field :node, field: GraphQL::Relay::Node.field

    field :viewer, Types::User, description: "The currently authenticated user.", null: false

    def viewer
      context[:current_user]
    end

    # I cannot explain why, but removing this field breaks everything
    # So I will let it live here, it's not hurting anyone.
    field :foo, Types::Classroom.connection_type, description: "foo", null: true, connection: true
  end
end
