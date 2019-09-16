# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:organization) { classroom_org }
  let(:lti_configuration) do
    create(:lti_configuration, organization: organization, consumer_key: "mock_token", shared_secret: "mock_secret")
  end
  let(:consumer_key) { lti_configuration.consumer_key }

  describe "sessions#failure", :vcr do
    it "redirects to lti_failure and curries request parameters when strategy is lti" do
      get :failure, params: { strategy: "lti" }

      expect(response).to redirect_to(auth_lti_failure_path(request.params))
    end

    it "renders auth failure otherwise" do
      get :failure

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eql("There was a problem authenticating with GitHub, please try again.")
    end
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

  describe "sessions#lti_failure" do
    it "raises LtiLaunchError" do
      bypass_rescue

      expect { get :lti_failure }.to raise_error(SessionsController::LtiLaunchError)
    end
  end

  describe "rescue_from :LtiLaunchError" do
    let(:launch_params) { {} }
    before(:each) do
      get :lti_failure, params: launch_params
    end

    context "message contains launch_presentation_return_url" do
      let(:return_url) { "https://return.example.com" }
      let(:launch_params) { { launch_presentation_return_url: return_url } }

      it "sets lti_errormsg query parameter" do
        redirect_location = URI.parse(response.location)
        params = Hash[URI.decode_www_form(redirect_location.query)]
        expect(params["lti_errormsg"]).to_not be_nil
      end

      it "redirects back to the given launch_presentation_return_url" do
        redirect_location = URI.parse(response.location)
        redirect_location.query = nil

        expect(redirect_location.to_s).to eq(return_url)
      end
    end

    context "message does not contain launch_presentation_return_url" do
      it "renders an error on the splash screen" do
        expect(response).to render_template(:lti_launch)
      end
    end
  end
end
