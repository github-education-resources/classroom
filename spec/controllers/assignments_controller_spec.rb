require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }

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

    it 'kicks of a background job to create a new AssignmentInvitation' do
      post :create, organization_id: organization.id, assignment: attributes_for(:assignment)

      assert_enqueued_jobs 1 do
        CreateAssignmentInvitationJob.perform_later(organization, assigns(:assignment))
      end
    end
  end

  describe 'GET #show', :vcr do
    let(:assignment) { Assignment.create(title: 'Assignment', creator: user, organization: organization) }

    it 'returns success status' do
      get :show, organization_id: assignment.organization.id, id: assignment.id
      expect(response).to have_http_status(:success)
    end
  end
end
