# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LTI launch", type: :request do
  let(:organization) { classroom_org }
  let(:lti_configuration) do
    create(
      :lti_configuration,
      organization:   organization,
      consumer_key:   "mock_token",
      shared_secret:  "mock_secret"
    )
  end
  let(:consumer_key) { lti_configuration.consumer_key }
  let(:redis_store) { Redis.new }

  before do
    GitHubClassroom.flipper[:lti_launch].enable
    GitHubClassroom.stub(:redis).and_return(redis_store)
  end

  after do
    GitHubClassroom.flipper[:lti_launch].disable
  end

  before(:each) do
    redis_store.flushdb
  end

  after(:each) do
    redis_store.quit
  end

  describe "sessions#lti_launch", :vcr do
    it "sets lti_nonce on session on success" do
      get auth_lti_launch_path(oauth_consumer_key: consumer_key)
      expect(session[:lti_nonce]).to eql("mock_nonce")
    end

    context "unauthenticated request" do
      it "redirects to sessions#new" do
        get auth_lti_launch_path(oauth_consumer_key: consumer_key)
        expect(response).to redirect_to(login_path) # /login
      end
    end

    context "authenticated request" do
      before(:each) do
        get url_for(organization)
        get response.redirect_url # /login
        get response.redirect_url # /auth/github
        get response.redirect_url # /auth/github/callback
      end

      it "redirects to linked organization" do
        get auth_lti_launch_path(oauth_consumer_key: consumer_key)
        expect(response).to redirect_to(edit_organization_path(id: organization.slug)) # /classrooms/:slug/settings
      end
    end
  end
end
