# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentRepoInfoController, type: :controller do
  let(:organization)      { classroom_org                                   }
  let(:user)              { classroom_teacher                               }
  let(:assignment)        { create(:assignment, organization: organization) }
  let(:group_assignment)  { create(:group_assignment, organization: organization) }

  before do
    sign_in_as(user)
  end

  describe "GET #info", :vcr do

    context "individual assignment" do
      before do
        get :info, params: {organization_id: organization.slug, assignment_id: assignment.slug, type: "individual"}
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns individual assignment title" do
        expect(json['name']).to eql(assignment.title)
      end

      it "returns individual assignment type" do
        expect(json['type']).to eql("individual")
      end
    end

    context "group assignment" do
      before do
        get :info, params: {organization_id: organization.slug, group_assignment_id: group_assignment.slug, type: "group"}
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns group assignment title" do
        expect(json['name']).to eql(group_assignment.title)
      end

      it "returns group assignment type" do
        expect(json['type']).to eql("group")
      end
    end

  end
end