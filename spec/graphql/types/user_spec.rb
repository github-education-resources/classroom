# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::User, :vcr do
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
    returned_user = data["data"]["node"]

    expect(data["errors"]).to be_nil

    expect(returned_user["id"]).to eq(user.global_relay_id)
    expect(returned_user["login"]).to_not be_nil
    expect(returned_user["githubUrl"]).to match(/http/)
    expect(returned_user["avatarUrl"]).to match(/http/)
  end
end
