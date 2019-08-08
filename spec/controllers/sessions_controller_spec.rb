# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:organization) { classroom_org }
  let(:lti_configuration) do
    create(:lti_configuration, organization: organization, consumer_key: "mock_token", shared_secret: "mock_secret")
  end
  let(:consumer_key) { lti_configuration.consumer_key }

  before do
    GitHubClassroom.flipper[:lti_launch].enable
  end

  after do
    GitHubClassroom.flipper[:lti_launch].disable
  end

  describe "sessions#lti_setup", :vcr do
    it "errors when consumer_key is present, no corresponding lti_configuration exists" do
      bypass_rescue

      LtiConfiguration.stub(:find_by).and_return(nil)
      expect { post :lti_setup, params: { oauth_consumer_key: lti_configuration.consumer_key } }
        .to raise_error(SessionsController::LtiLaunchError)
    end

    it "errors when omniauth strategy request env variable is not present" do
      bypass_rescue

      expect { get :lti_setup, params: { oauth_consumer_key: lti_configuration.consumer_key } }
        .to raise_error(SessionsController::LtiLaunchError)
    end

    it "succeeeds" do
      options = double("options")
      allow(options).to receive(:consumer_key=)
      allow(options).to receive(:shared_secret=)

      strategy = double("omniauth.strategy", options: options)

      Rails.application.env_config["omniauth.strategy"] = strategy
      get :lti_setup, params: { oauth_consumer_key: lti_configuration.consumer_key }
      Rails.application.env_config["omniauth.strategy"] = nil

      expect(response).to have_http_status(200)
    end
  end

  describe "rescue_from :LtiLaunchError" do
  end
end
