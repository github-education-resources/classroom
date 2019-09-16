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
    GitHubClassroom.stub(:redis).and_return(redis_store)
  end

  before(:each) do
    redis_store.flushdb
  end

  after(:each) do
    redis_store.quit
  end

  describe "sessions#lti_launch", :vcr do
    context "invalid launch" do
      before(:each) do
        @previous_mock_lti_response = OmniAuth.config.mock_auth[:lti]
        OmniAuth.config.mock_auth[:lti] = :invalid_credentials
      end

      after(:each) do
        OmniAuth.config.mock_auth[:lti] = @previous_mock_lti_response
      end

      it "redirects to the failure path" do
        post auth_lti_launch_path(oauth_consumer_key: consumer_key)
        redirect_location = URI.parse(response.location)

        expect(redirect_location.path).to eql(auth_failure_path)
      end
    end

    context "valid launch" do
      it "sets cached_launch_message_nonce on corresponding lti_configuration" do
        post auth_lti_launch_path(oauth_consumer_key: consumer_key)
        lti_configuration.reload
        expect(lti_configuration.cached_launch_message_nonce).to eql("mock_nonce")
      end

      it "renders lti_launch template" do
        post auth_lti_launch_path(oauth_consumer_key: consumer_key)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:lti_launch)
      end

      context "unauthenticated request" do
        it "post_launch_url is set to sessions#new" do
          post auth_lti_launch_path(oauth_consumer_key: consumer_key)
          expect(assigns[:post_launch_url]).to eq(login_url) # /login
        end
      end

      context "authenticated request" do
        before(:each) do
          get url_for(organization)
          get response.redirect_url # /login
          get response.redirect_url # /auth/github
          get response.redirect_url # /auth/github/callback
        end

        it "post_launch_url is set to LtiConfigurations#complete" do
          post auth_lti_launch_path(oauth_consumer_key: consumer_key)
          expect(assigns[:post_launch_url]).to eq(complete_lti_configuration_url(id: organization.slug))
        end
      end
    end
  end
end
