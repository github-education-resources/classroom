require 'rails_helper'

RSpec.describe "Error 404", type: :request do

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }

  before(:all) do
    Rails.application.config.action_dispatch.show_exceptions = true
    Rails.application.config.consider_all_requests_local = false
  end

  after(:all) do
    Rails.application.config.action_dispatch.show_exceptions = false
    Rails.application.config.consider_all_requests_local = true
  end

  describe 'GET #error404' do
    it 'returns not found error 404' do
      get '/404'
      expect(response).to redirect_to(not_found_path)
    end
  end

  describe 'GET /any-other-page' do
    
    before(:each) do
        get url_for(organization)
        get response.redirect_url # http://www.example.com/login
        get response.redirect_url # http://www.example.com/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg
        get response.redirect_url # http://www.example.com/auth/github/callback
    end

    it 'shows invalid invitation message' do
      get '/assignment-invitations/invalid-link'
      expect(response.status).to eq(404)
      within '#error' do
        has_content? 'Invalid Invitation Link! Please contact your organization.'
      end 
    end

    it 'shows general page not found message' do
      get '/not-existing-page'
      expect(response.status).to eq(404)
      within '#error' do
        has_content? 'Page Could not be Found.'
      end
    end
  end
end
