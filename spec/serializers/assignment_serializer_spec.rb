# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentSerializer, type: :serializer do
  let(:organization)      { classroom_org                                                           }
  let(:assignment)        { create(:assignment, organization: organization, title: "Learn Clojure") }

  describe "AssignmentSerializer attributes check", :vcr do
    before(:each) do
      @assignment_json = described_class.new(assignment).as_json
    end

    it "returns assignment id" do
      expect(@assignment_json[:id]).to eq(assignment.id)
    end

    it "returns assignment title" do
      expect(@assignment_json[:title]).to eq(assignment.title)
    end

    it "returns assignment type" do
      expect(@assignment_json[:type]).to eq(:individual)
    end

    it "returns organization github id" do
      expect(@assignment_json[:organizationGithubId]).to eq(organization.github_id)
    end
  end
end
