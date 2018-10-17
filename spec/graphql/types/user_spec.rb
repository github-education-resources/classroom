require "rails_helper"

RSpec.describe Types::User do
  let(:user) { classroom_teacher }

  it "returns fields" do
    query = <<~GRAPHQL
      query($id: ID!) {
        node(id: $id) {
          ... on User {
            id
            login
            avatarUrl
            githubUrl
          }
        }
      }
    GRAPHQL

    data = graphql_query(query, variables: { id: user.global_relay_id }, as: user)
    user = data["data"]["node"]

    expect(data["errors"]).to be_nil

    expect(user["id"]).to eq(user.global_relay_id)
    expect(user["login"]).to_not be_nil
    expect(user["githubUrl"]).to match(/github\.com/)
    expect(user["avatarUrl"]).to match(/github\.com/)
  end
end
