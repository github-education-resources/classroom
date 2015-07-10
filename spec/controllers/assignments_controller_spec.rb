require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:user)         { create(:user_with_organizations) }
  let(:organization) { user.organizations.first }

  let(:org_login) { 'ord_login' }

  before do
    session[:user_id] = user.id
  end

  before(:each) do
    @request_stubs = []
  end

  after(:each) do
    @request_stubs.each do |request_stub|
      expect(request_stub).to have_been_requested.once
    end
  end

  describe 'GET #new' do
    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'returns success status' do
      get :new, organization_id: organization.id
      expect(response).to have_http_status(:success)
    end

    it 'has a new Assignment' do
      get :new, organization_id: organization.id
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe 'POST #create' do
    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

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

  describe 'GET #show' do
    let(:assignment) { create(:assignment) }
    let(:assignment_organization) { assignment.organization }

    before(:each) do
      @request_stubs << stub_github_organization(assignment_organization.github_id,
                                                 login: org_login,
                                                 id: assignment_organization.github_id)

      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'returns success status' do
      get :show, organization_id: assignment_organization.id, id: assignment.id
      expect(response).to have_http_status(:success)
    end
  end
end
