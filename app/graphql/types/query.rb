# frozen_string_literal: true

require "graphql"

require_relative "user"

class Types
  class Query < GraphQL::Schema::Object
    field :node, field: GraphQL::Relay::Node.field

    field :viewer, Types::User, description: "The currently authenticated user.", null: false

    def viewer
      context[:current_user]
    end

    field :test, String, null: false

    def test
      "I am working!"
    end
  end
end
