# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render body: nil, status: :ok
    end
  end

  let(:user)    { classroom_teacher }

  before(:each) do
    sign_in_as(user)
  end

  describe "user authentication tests" do

    context "user access token is valid", :vcr do
      it "should render action" do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "user access token is no longer valid" do
      before do
        User.any_instance.stub(:github_client_scopes).and_return([])
      end
      it "should logout user and delete session" do
        get :index
        expect(response).to redirect_to(login_path)
        expect(session[:pre_login_destination]).to eq("http://test.host/anonymous")
        expect(session[:required_scopes]).to eq(GitHubClassroom::Scopes::TEACHER.join(","))
      end
    end

  end
end
