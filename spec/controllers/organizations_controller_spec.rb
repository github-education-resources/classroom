require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #new', :vcr do
    it 'returns success status' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'has a new organization' do
      get :new
      expect(assigns(:organization)).to_not be_nil
    end

    it 'has an array of the users GitHub organizations that they are an admin of' do
      get :new
      expect(assigns(:users_github_organizations).class).to eq(Array)
    end
  end

  describe 'POST #create', :vcr do
    it 'will add an organization' do
      organization = build(:organization)
      organization_options = { title: organization.title, github_id: organization.github_id }

      expect { post :create, organization: organization_options }.to change { Organization.count }
      expect(response).to redirect_to(invite_organization_path(Organization.last))
    end

    it 'will not add an organization that already exists' do
      existing_organization = user.organizations.first

      organization_options = { title: existing_organization.title, github_id: existing_organization.github_id }
      expect { post :create, organization: organization_options }.to_not change { Organization.count }
    end
  end

  describe 'GET #show' do
    it 'returns success and sets the organization' do
      get :show, id: organization.id

      expect(response.status).to eq(200)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'GET #edit' do
    it 'returns success and sets the organization' do
      get :edit, id: organization.id

      expect(response).to have_http_status(:success)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'PATCH #update' do
    it 'correctly updates the organization' do
      options = { title: 'New Title' }
      patch :update, id: organization.id, organization: options

      expect(response).to redirect_to(organization_path(organization))
    end
  end

  describe 'DELETE #destroy', :vcr do
    it 'deletes the organization' do
      expect { delete :destroy, id: organization.id }.to change { Organization.count }
    end

    it 'redirects back to the dashboard' do
      delete :destroy, id: organization.id
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'GET #invite', :vcr do
    it 'returns an array of organization admins that have not been added to classroom' do
    end
  end

  describe 'GET #invite_users', :vcr do
    it 'calls the InviteUserToClassroomJob for each new user' do
    end
  end
end
