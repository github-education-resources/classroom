require 'rails_helper'
require 'set'
RSpec.describe AutocompleteController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  before do
    sign_in(user)
  end

  describe 'GET #github_repos', :vcr do
    it 'returns success and returns a subset of repos of the user' do
      get :github_repos

      expect(response).to have_http_status(:success)

      returned_repo_ids = assigns(:repos).map { |repo| repo[:id] }.to_set
      actual_repo_ids = user.github_client.repos.map { |repo| repo[:id] }.to_set
      expect(returned_repo_ids).to be_subset(actual_repo_ids)

      expect(response).to render_template(partial: 'autocomplete/_repository_suggestions')
    end

    it 'returns success and returns search results of a query' do
      get :github_repos, query: 'rails/rails'
      expect(response).to have_http_status(:success)

      returned_repo_ids = assigns(:repos).map { |repo| repo[:id] }.to_set
      actual_repo_ids = user
                        .github_client
                        .search_repos('rails user:rails fork:true')[:items]
                        .map { |repo| repo[:id] }.to_set
      expect(returned_repo_ids).to be_subset(actual_repo_ids)

      expect(response).to render_template(partial: 'autocomplete/_repository_suggestions')
    end
  end
end
