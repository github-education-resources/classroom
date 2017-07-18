# frozen_string_literal: true

require "rails_helper"
require "set"

RSpec.describe AutocompleteController, type: :controller do
  let(:user) { classroom_teacher }

  before do
    sign_in_as(user)
  end

  describe "GET #github_repos", :vcr do
    before do
      get :github_repos
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "renders correct template" do
      expect(response).to render_template(partial: "autocomplete/_repository_suggestions")
    end
  end
end
