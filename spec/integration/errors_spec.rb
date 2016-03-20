require 'rails_helper'

RSpec.describe "Error page", :type => :request do
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
      expect(response.status).to eq(404)
    end
  end

  describe 'GET /any-other-page' do
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