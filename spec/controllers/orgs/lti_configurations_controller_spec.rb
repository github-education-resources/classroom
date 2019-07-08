# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::LtiConfigurationsController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }

  before(:each) do
    sign_in_as(user)
    GitHubClassroom.flipper[:lti_launch].enable
  end

  describe "GET #new" do
    it "returns success status" do
      get :new, params: { organization: organization }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns success status" do
      get :show, params: { organization: organization }
      expect(response).to have_http_status(:success)
    end
  end

  describe "flag is turned off" do
    before(:each) do
      GitHubClassroom.flipper[:lti_launch].disable
    end

    it "returns not found for #new" do
      get :new, params: { organization: organization }
      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for #show" do
      get :show, params: { organization: organization }
      expect(response).to have_http_status(:not_found)
    end
  end
end
