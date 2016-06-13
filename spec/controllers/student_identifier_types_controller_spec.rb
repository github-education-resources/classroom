# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifierTypesController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }
  let(:student)       { GitHubFactory.create_classroom_student   }
  let(:student_identifier_type) do
    StudentIdentifierType.create!(organization: organization,
                                  name: 'Test',
                                  description: 'Test',
                                  content_type: 'text')
  end

  before do
    sign_in(user)
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

  describe 'DELETE #destroy', :vcr do
    it 'sets the `deleted_at` column' do
      student_identifier_type
      expect do
        delete :destroy, id: student_identifier_type.id, organization_id: organization
      end.to change { StudentIdentifierType.all.count }
      expect(StudentIdentifierType.unscoped.find(student_identifier_type.id).deleted_at).not_to be_nil
    end

    it 'calls the DestroyResource background job' do
      delete :destroy, id: student_identifier_type.id, organization_id: organization

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(student_identifier_type)
      end
    end

    it 'redirects back to the student identifier type index' do
      delete :destroy, id: student_identifier_type.id, organization_id: organization
      expect(response).to redirect_to(organization_student_identifier_types_path(organization))
    end
  end
end
