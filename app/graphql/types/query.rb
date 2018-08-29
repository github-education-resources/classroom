require_relative "../loaders/github_loader"
require "graphql"

require_relative "assignment_repo"
require_relative "user"
require_relative "classroom"
require_relative "assignment"

class Types
  class Query < GraphQL::Schema::Object
    field :node, field: GraphQL::Relay::Node.field

    field :viewer, Types::User, description: "The currently authenticated user.", null: false

    def viewer
      context[:current_user]
    end

    # I cannot explain why, but removing this field breaks everything.
    # So I will let it live here, it's not hurting anyone.
    # TODO: Fix the weird autoloading jank
    field :classrooms, Types::Classroom.connection_type, null: true, connection: true
  end
end
