# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::UsersController, type: :controller do
  let(:user) { classroom_teacher }

  describe "GET #authenticated_user", :vcr do
    before do
      get :authenticated_user, params: {
        access_token: user.api_token
      }
    end

    it "returns success" do
      expect(response).to have_http_status(200)
    end

    it "returns correct attributes in user serializer" do
      expect(json["id"]).to eq(user.id)
      expect(json["username"]).to eq(user.github_user.login)
    end
  end
end
