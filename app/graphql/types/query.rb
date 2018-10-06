require "graphql"

class Types
  class Query < GraphQL::Schema::Object
    field :test, String, null: false

    def test
      "I am working!"
    end
  end
end
