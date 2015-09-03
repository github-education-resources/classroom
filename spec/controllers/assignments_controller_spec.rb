require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  let(:assignment) { Assignment.create(title: 'Assignment', creator: user, organization: organization) }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #new', :vcr do
    it 'returns success status' do
      get :new, organization_id: organization.id
      expect(response).to have_http_status(:success)
    end

    it 'has a new Assignment' do
      get :new, organization_id: organization.id
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe 'POST #create', :vcr do
    it 'creates a new Assignment' do
      expect do
        post :create, organization_id: organization.id, assignment: attributes_for(:assignment)
      end.to change { Assignment.count }
    end
  end

  describe 'GET #show', :vcr do
    it 'returns success status' do
      get :show, organization_id: organization.id, id: assignment.id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit', :vcr do
    it 'returns success and sets the assignment' do
      get :edit, id: assignment.id, organization_id: organization.id

      expect(response).to have_http_status(:success)
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe 'PATCH #update', :vcr do
    it 'correctly updates the assignment' do
      options = { title: 'Ruby on Rails' }
      patch :update, id: assignment.id, organization_id: organization.id, assignment: options

      expect(response).to redirect_to(organization_assignment_path(organization, assignment))
    end
  end

  describe 'DELETE #destroy', :vcr do
    it 'sets the `deleted_at` column for the assignment' do
      assignment
      expect { delete :destroy, id: assignment.id, organization_id: organization }.to change { Assignment.all.count }
      expect(Assignment.unscoped.find(assignment.id).deleted_at).not_to be_nil
    end

    it 'calls the DestroyResource background job' do
      delete :destroy, id: assignment.id, organization_id: organization

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(assignment)
      end
    end

    it 'redirects back to the organization' do
      delete :destroy, id: assignment.id, organization_id: organization.id
      expect(response).to redirect_to(organization)
    end
  end
end
