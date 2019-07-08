# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::LtiConfigurationsController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #new", :vcr do
    context "with flipper disabled" do
      before(:each) do
        GitHubClassroom.flipper[:lti_launch].disable
      end

      it "returns not_found" do
        get :new, params: { id: organization.slug }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with flipper enabled" do
      before(:each) do
        GitHubClassroom.flipper[:lti_launch].enable
      end

      it "returns success status" do
        get :new, params: { id: organization.slug }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #show", :vcr do
    context "with flipper disabled" do
      before(:each) do
        GitHubClassroom.flipper[:lti_launch].disable
      end

      it "returns not_found" do
        get :show, params: { id: organization.slug }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with flipper enabled" do
      before(:each) do
        GitHubClassroom.flipper[:lti_launch].enable
      end

      context "with lti_configuration present" do
        before(:each) do
          create(:lti_configuration, organization: organization)
        end

        it "returns success status" do
          get :show, params: { id: organization.slug }
          expect(response).to have_http_status(:success)
        end
      end

      context "with no existing lti_configuration" do
        it "redirects to new" do
          get :show, params: { id: organization.slug }
          expect(response).to redirect_to(new_lti_configuration_path(organization))
        end
      end
    end
  end
end
