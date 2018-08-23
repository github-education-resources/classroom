require "rails_helper"

RSpec.describe Types::Query do
  let(:teacher) { classroom_teacher }

  describe "fields" do
    context "viewer" do
      it "returns the correct viewer" do
        query = "query{ viewer { id } }"

        data = graphql_query(query, as: teacher)

        expect(data["errors"]).to be_nil
        expect(data["data"]["viewer"]["id"]).to eq(teacher.global_relay_id)
      end
    end
  end
end
