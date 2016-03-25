require 'rails_helper'
require 'set'

RSpec.describe AutocompleteController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  before do
    sign_in(user)
  end

  describe 'GET #github_repos', :vcr do
    context 'no search query is passed' do
      before do
        get :github_repos
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns a subset of repos that the current user has access to' do
        returned_repo_ids = assigns(:repos).map { |repo| repo[:id] }.to_set
        actual_repo_ids = user.github_client.repos.map { |repo| repo[:id] }.to_set
        expect(returned_repo_ids).to be_subset(actual_repo_ids)
      end

      it 'renders correct template' do
        expect(response).to render_template(partial: 'autocomplete/_repository_suggestions')
      end
    end

    context 'a search query is passed' do
      before do
        get :github_repos, query: 'rails/rails'
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns search results of a query' do
        returned_repo_ids = assigns(:repos).map { |repo| repo[:id] }.to_set
        actual_repo_ids = user
                          .github_client
                          .search_repos('rails user:rails fork:true')[:items]
                          .map { |repo| repo[:id] }.to_set
        expect(returned_repo_ids).to be_subset(actual_repo_ids)
      end

      it 'renders correct template' do
        expect(response).to render_template(partial: 'autocomplete/_repository_suggestions')
      end
    end
  end
end
