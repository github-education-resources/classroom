class Types
  class MutationType < GraphQL::Schema::Object
    # TODO: Remove me
    field :test_field, String, description: "An example field added by the generator", null: true

    def test_field
      "Hello World!"
    end
  end
end
