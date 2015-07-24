require 'rails_helper'

RSpec.describe GroupAssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

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

    it 'kicks of a background job to create a new GroupAssignmentInvitation' do
      post :create, organization_id: organization.id,
                    group_assignment: { title: 'Learn JavaScript' },
                    grouping: { title: 'Grouping 1' }

      assert_enqueued_jobs 2 do
        CreateGroupingJob.perform_later(GroupAssignment.last, title: 'Learn JavaScript')
        CreateGroupAssignmentInvitationJob.perform_later(organization, assigns(:group_assignment))
      end
    end
  end

  describe 'GET #show', :vcr do
    let(:group_assignment) do
      GroupAssignment.create(attributes_for(:group_assignment).merge(organization: organization, creator: user))
    end

    it 'returns success status' do
      get :show, organization_id: organization.id, id: group_assignment.id
      expect(response).to have_http_status(:success)
    end
  end
end
