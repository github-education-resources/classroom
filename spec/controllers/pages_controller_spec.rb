# frozen_string_literal: true

require "rails_helper"

RSpec.describe PagesController, type: :controller do
  describe "GET #home" do
    it "returns success" do
      get :home
      expect(response).to have_http_status(:success)
    end

    it "redirects to the dashboard if the user is already logged in" do
      sign_in_as(create(:user))

      get :home
      expect(response).to redirect_to(organizations_path)
    end
  end
end
