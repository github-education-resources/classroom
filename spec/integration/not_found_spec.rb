require 'rails_helper'

RSpec.describe "Not Found", type: :request do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }
  
  before do
    sign_in(user)
  end

  describe 'match #error404' do
    it 'returns not found error 404' do
      match "/404"
      expect(response).to redirect_to(not_found_path)
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