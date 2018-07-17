# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentsController, type: :controller do
  let(:organization)      { classroom_org                                   }
  let(:user)              { classroom_teacher                               }
  

  before do
    sign_in_as(user)
  end

  describe "GET #index", :vcr do

    context "only individual assignment" do
      before do
        @assignment = create(:assignment, organization: organization)
        get :index, params: {organization_id: organization.slug}
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns only one assignment" do
        expect(json.length).to eql(1)
      end

      it "returns assignment title" do
        expect(json.first['title']).to eql(@assignment.title)
      end

      it "returns individual assignment type" do
        expect(json.first['type']).to eql("individual")
      end
    end

    context "only group assignment" do
      before do
        @group_assignment = create(:group_assignment, organization: organization)
        get :index, params: {organization_id: organization.slug}
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns only one assignment" do
        expect(json.length).to eql(1)
      end

      it "returns group assignment title" do
        expect(json.first['title']).to eql(@group_assignment.title)
      end

      it "returns group assignment type" do
        expect(json.first['type']).to eql("group")
      end
    end

    context "both individual and group assignments" do
      before do
        @group_assignment = create(:group_assignment, organization: organization)
        @individual_assignment = create(:assignment, organization: organization)
        get :index, params: {organization_id: organization.slug}
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns both assignments" do
        expect(json.length).to eql(2)
      end
    end

  end
end