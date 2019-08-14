# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render body: nil, status: :ok
    end

    def unknown_format; end

    def template_not_found
      render layout: "layouts/pages"
    end
  end

  let(:user)    { classroom_teacher }

  before(:each) do
    sign_in_as(user)
  end

  describe "user authentication tests" do
    context "user access token is valid", :vcr do
      it "renders action" do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "user access token is not authorized" do
      before do
        allow_any_instance_of(User).to receive(:authorized_access_token?).and_return(false)
      end

      it "redirects to home page" do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it "flashes correct error message" do
        get :index
        expect(flash[:error]).to eq("Access Token is invalid. Please login again.")
      end

      it "resets the session except flash message" do
        get :index
        expect(session.to_hash.except("flash")).to be_empty
      end
    end
  end

  describe "error handling", :vcr do
    before do
      routes.draw do
        get "unknown_format" => "anonymous#unknown_format"
        get "template_not_found" => "anonymous#template_not_found"
      end
    end

    it "returns 406 and notifies statsd for unknown format" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("errors.action_controller_unknown_format")
      get :unknown_format
      assert_response 406
    end

    it "returns 406 and notifies statsd when a template cannot be found" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("errors.action_view_missing_template")
      get :template_not_found, format: :json
      assert_response 406
    end
  end
end
