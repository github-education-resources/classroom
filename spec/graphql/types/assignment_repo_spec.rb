require "rails_helper"

RSpec.describe Types::AssignmentRepo do
  let(:organization)    { classroom_org     }
  let(:teacher)         { classroom_teacher }
  let(:rando)           { create(:user)     }
  let(:assignment)      { create(:assignment, organization: organization)  }
  let(:assignment_repo) { create(:assignment_repo, assignment: assignment) }

  describe "authorization checks" do
    context "when current_user is not an admin of the assignment organization" do
      it "does not grant access" do
        query = "query($id: ID!) { node(id: $id) { ... on AssignmentRepo { id } } }"

        data = graphql_query(query, variables: { id: assignment_repo.global_relay_id }, as: rando)

        expect(data["node"]).to be_nil
      end
    end

    context "when current_user is an admin on the assignment organization" do
      it "grants access" do
        query = "query($id: ID!) { node(id: $id) { ... on AssignmentRepo { id } } }"

        data = graphql_query(query, variables: { id: assignment_repo.global_relay_id }, as: teacher)

        expect(data["errors"]).to be_nil
        expect(data["data"]["node"]["id"]).to eq(assignment_repo.global_relay_id)
      end
    end
  end
end
