require 'rails_helper'

RSpec.describe GroupAssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  let(:group_assignment) do
    GroupAssignment.create(attributes_for(:group_assignment).merge(organization: organization, creator: user))
  end

  before do
    session[:user_id] = user.id
  end

  describe 'GET #new', :vcr do
    it 'returns success status' do
      get :new, organization_id: organization.id
      expect(response).to have_http_status(:success)
    end

    it 'has a new GroupAssignment' do
      get :new, organization_id: organization.id
      expect(assigns(:group_assignment)).to_not be_nil
    end
  end

  describe 'POST #create', :vcr do
    it 'creates a new GroupAssignment' do
      expect do
        post :create, organization_id: organization.id,
                      group_assignment: { title: 'Learn JavaScript' },
                      grouping:         { title: 'Grouping 1'       }
      end.to change { GroupAssignment.count }
    end
  end

  describe 'GET #show', :vcr do
    it 'returns success status' do
      get :show, organization_id: organization.id, id: group_assignment.id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit', :vcr do
    it 'returns success status and sets the group assignment' do
      get :edit, organization_id: organization.id, id: group_assignment.id

      expect(response).to have_http_status(:success)
      expect(assigns(:group_assignment)).to_not be_nil
    end
  end

  describe 'PATCH #update', :vcr do
    it 'correctly updates the assignment' do
      options = { title: 'JavaScript Calculator' }
      patch :update, id: group_assignment.id, organization_id: organization.id, group_assignment: options

      expect(response).to redirect_to(organization_group_assignment_path(organization, group_assignment))
    end
  end

  describe 'DELETE #destroy', :vcr do
    it 'sets the `deleted_at` column for the group assignment' do
      group_assignment

      expect do
        delete :destroy, id: group_assignment.id, organization_id: organization
      end.to change { GroupAssignment.all.count }

      expect(GroupAssignment.unscoped.find(group_assignment.id).deleted_at).not_to be_nil
    end

    it 'calls the DestroyResource background job' do
      delete :destroy, id: group_assignment.id, organization_id: organization

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(group_assignment)
      end
    end

    it 'redirects back to the organization' do
      delete :destroy, id: group_assignment.id, organization_id: organization.id
      expect(response).to redirect_to(organization)
    end
  end
end
