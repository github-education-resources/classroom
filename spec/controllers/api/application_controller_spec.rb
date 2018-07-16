# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }
  let(:assignment)   { create(:assignment, organization: organization) }

  before do
    sign_in_as(user)
  end

  describe "GET #info", :vcr do
    context "unauthenticated user" do
      before do
        sign_out
      end

      it "returns 403 forbidden" do
        # get :info, params: {organization_id: organization.slug, assignment_id: assignment.slug}
        # get api_organization_assignment_info_path(organization_id: organization.slug, assignment_id: assignment.slug)
        expect(response).to have_http_status(:forbidden)
      end
    end

    # context "authenticated user" do
    #   it "returns success" do
    #     get api_organization_assignments_path(organization_id: organization.slug)
    #     expect(response).to have_http_status(:success)
    #   end

    #   it "returns all of user's assignments" do
    #     get api_organization_assignments_path(organization_id: organization.slug)
    #     binding.pry
    #     # expect(json)
    #   end
    # end

  end
end