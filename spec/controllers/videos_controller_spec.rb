# frozen_string_literal: true

require "rails_helper"

RSpec.describe VideosController, type: :controller do
  describe "GET #index" do
    it "returns a success status" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end
