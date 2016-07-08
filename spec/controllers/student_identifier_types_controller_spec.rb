# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifierTypesController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }
  let(:student)       { GitHubFactory.create_classroom_student   }

  let(:student_identifier_type) { GitHubFactory.create_student_identifier(organization) }

  before do
    sign_in(user)
    Classroom.flipper[:student_identifier].enable
  end

  describe 'GET #index', :vcr do
    it 'returns success status' do
      get :index, organization_id: organization.slug

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new', :vcr do
    it 'returns success status' do
      get :new, organization_id: organization.slug

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create', :vcr do
    it 'creates a new StudentIdentifierType' do
      expect do
        post :create,
             organization_id: organization.slug,
             student_identifier_type: { name: 'Test', description: 'Test', content_type: 'text' }
      end.to change { StudentIdentifierType.count }
    end
  end
end
