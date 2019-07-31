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

  describe "sessions#lti_setup", :vcr do
    it "errors when no consumer_key is present" do
      expect { get auth_lti_setup_path }.to raise_error(ActionController::BadRequest)
    end

    it "errors when consumer_key is present, no corresponding lti_configuration exists" do
      LtiConfiguration.stub(:find_by).and_return(nil)

      expect { get auth_lti_setup_path(oauth_consumer_key: lti_configuration.consumer_key) }
        .to raise_error(ActionController::BadRequest)
    end

    it "errors when omniauth strategy request env variable is not present" do
      expect { get auth_lti_setup_path(oauth_consumer_key: lti_configuration.consumer_key) }
        .to raise_error(ActionController::BadRequest)
    end

    it "succeeeds" do
      options = double("options")
      allow(options).to receive(:consumer_key=)
      allow(options).to receive(:shared_secret=)

      strategy = double("omniauth.strategy", options: options)

      Rails.application.env_config["omniauth.strategy"] = strategy
      get auth_lti_setup_path(oauth_consumer_key: lti_configuration.consumer_key)
      Rails.application.env_config["omniauth.strategy"] = nil

      expect(response).to have_http_status(200)
    end
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

      it "redirects to lms success page" do
        get auth_lti_launch_path(oauth_consumer_key: consumer_key)
        expect(response).to redirect_to(complete_lti_configuration_path(id: organization.slug))
      end
    end
  end
end
