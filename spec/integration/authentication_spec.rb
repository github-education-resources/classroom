require 'rails_helper'

RSpec.describe 'OAuth scope requirements', type: :request do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  describe 'unauthenticated organization#show' do
    it 'redirects to session#new' do
      get url_for(organization)
      expect(response).to redirect_to(login_path)
    end

    it 'sets required scopes in session' do
      get url_for(organization)
      expect(session[:required_scopes]).to eq('user:email,repo,delete_repo,admin:org')
    end
  end

  describe 'session#new' do
    before(:each) do
      get url_for(organization)
    end

    it 'redirects to omniauth' do
      get response.redirect_url
      expect(response).to redirect_to('/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg')
    end
  end

  describe 'OAuth dance', :vcr do
    before(:each) do
      get url_for(organization)
      get response.redirect_url # http://www.example.com/login
      get response.redirect_url # http://www.example.com/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg
    end

    it 'redirects back to organization#show' do
      get response.redirect_url # http://www.example.com/auth/github/callback
      expect(response).to redirect_to(url_for(organization))
    end
  end

  describe 'authentication organization#show', :vcr do
    before(:each) do
      get url_for(organization)
      get response.redirect_url # http://www.example.com/login
      get response.redirect_url # http://www.example.com/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg
      get response.redirect_url # http://www.example.com/auth/github/callback
    end

    it 'renders organization#show' do
      get response.redirect_url
      expect(response.status).to eq(200)
      expect(response).to render_template("organizations/show")
    end
  end
end
