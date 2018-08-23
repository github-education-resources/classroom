require "rails_helper"

RSpec.describe Types::User do
  let(:user) { create(:user) }

  it "can be looked up by global relay ID" do
    query = <<~GRAPHQL
      query($id: ID!) { node(id: $id) { ... on User { id } } }
    GRAPHQL

    data = graphql_query(query, variables: { id: user.global_relay_id }, as: user)

    expect(data["errors"]).to be_nil
    expect(data["data"]["node"]["id"]).to eq(user.global_relay_id)
  end
end
