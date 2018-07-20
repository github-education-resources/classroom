# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentSerializer, type: :serializer do
  let(:organization)      { classroom_org                                                                 }
  let(:group_assignment)  { create(:group_assignment, organization: organization, title: "Learn Clojure") }

  describe "GroupAssignmentSerializer attributes check", :vcr do
    before(:each) do
      @group_assignment_json = described_class.new(group_assignment).as_json
    end

    it "returns assignment id" do
      expect(@group_assignment_json[:id]).to eq(assignment.id)
    end

    it "returns assignment title" do
      expect(@group_assignment_json[:title]).to eq(assignment.title)
    end

    it "returns assignment type" do
      expect(@group_assignment_json[:type]).to eq(:individual)
    end

    it "returns organization github id" do
      expect(@group_assignment_json[:organizationGithubId]).to eq(organization.github_id)
    end
  end
end
