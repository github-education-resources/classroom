# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentRepoInfoController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }
  let(:assignment)   { create(:assignment, organization: organization) }

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

      it "returns all of user's assignments" do
        binding.pry
        # get :info, params: {organization_id: organization.slug, assignment_id: assignment.title}
        # expect(json)
      end
    end

    context "group assignment" do
      before do
        get :info, params: {organization_id: organization.slug, assignment_id: assignment.slug, type: "group"}
      end
      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all of user's assignments" do
        binding.pry
        # get :info, params: {organization_id: organization.slug, assignment_id: assignment.title}
        # expect(json)
      end
    end

  end
end