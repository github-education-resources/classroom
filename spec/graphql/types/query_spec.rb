# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::Query do
  let(:teacher) { classroom_teacher }

  describe "fields" do
    context "test" do
      it "returns the correct string" do
        query = "query{ test }"

        data = graphql_query(query, as: teacher)

        expect(data["errors"]).to be_nil
        expect(data["data"]["test"]).to eq("I am working!")
      end
    end
  end
end
