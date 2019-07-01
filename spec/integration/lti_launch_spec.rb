# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LTI launch", type: :request do
  let(:organization) { classroom_org }

  before do
    GitHubClassroom.flipper[:lti_launch].enable
  end

  after do
    GitHubClassroom.flipper[:lti_launch].disable
  end

  describe "sessions#lti_launch", :vcr do
    context "unauthenticated request" do
      it "redirects to sessions#new" do
        get auth_lti_launch_path # /auth/lti/launch
        expect(response).to redirect_to(login_path) # /login
      end

      it "sets lti_uid on session" do
        get auth_lti_launch_path # /auth/lti/launch
        expect(session[:lti_uid]).to eql("mock_lti_uid")
      end
    end

    context "authenticated request" do
      before(:each) do
        get url_for(organization)
        get response.redirect_url # /login
        get response.redirect_url # /auth/github
        get response.redirect_url # /auth/github/callback
      end

      it "redirects to sessions#lti_callback" do
        get auth_lti_launch_path # /auth/lti/launch
        expect(response).to redirect_to(auth_lti_callback_path) # /auth/lti/callback
      end

      it "has access to a logged in user" do
        get auth_lti_launch_path # /auth/lti/launch
        session[:user_id].should_not be_nil
      end

      it "has lti_uid set on session" do
        get auth_lti_launch_path # /auth/lti/launch
        expect(session[:lti_uid]).to eql("mock_lti_uid")
      end
    end
  end
end
