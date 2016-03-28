require 'rails_helper'
require 'set'

RSpec.describe AutocompleteController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  before do
    sign_in(user)
  end

  describe 'GET #github_repos', :vcr do
    before do
      get :github_repos
    end

    it 'returns success' do
      expect(response).to have_http_status(:success)
    end

    it 'renders correct template' do
      expect(response).to render_template(partial: 'autocomplete/_repository_suggestions')
    end
  end
end
