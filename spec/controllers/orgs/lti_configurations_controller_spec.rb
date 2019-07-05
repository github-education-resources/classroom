# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::LtiConfigurationsController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }

  before(:each) do
    sign_in_as(user)
    GitHubClassroom.flipper[:lti_launch].enable
  end

  describe "GET #link_lms_classroom", :vcr do
    it "returns success status" do
      binding.pry
      get :link_lms_classroom, params: { organization: organization }
      expect(response).to have_http_status(:success)
      binding.pry
    end
  end

  describe "GET #lms_configuration", :vcr do
    it "returns success status" do
      get :lms_configuration, params: { organization: organization }
      expect(response).to have_http_status(:success)
    end
  end

  describe "flag is turned off", :vcr do
    before(:each) do
      GitHubClassroom.flipper[:lti_launch].disable
    end

    it "returns not found for link_lms_classroom" do
      get :link_lms_classroom, params: { organization: organization }
      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for lms_configuration" do
      get :lms_configuration, params: { organization: organization }
      expect(response).to have_http_status(:not_found)
    end
  end
end
