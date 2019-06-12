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
      it "renders action" do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "user access token is not authorized" do
      before do
        User.any_instance.stub(:authorized_access_token?).and_return(false)
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
end
