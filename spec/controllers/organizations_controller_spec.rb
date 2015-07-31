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
      expect(assigns(:users_github_organizations)).to be_kind_of(Array)
    end

    it 'will not include any organizations that are already apart of classroom' do
      get :new
      expect(assigns(:users_github_organizations)).not_to include([organization.title, organization.github_id])
    end
  end

  describe 'POST #create', :vcr do
    it 'will add an organization' do
      new_organization = build(:organization)
      new_organization_options = { title: new_organization.title, github_id: new_organization.github_id }

      expect { post :create, organization: new_organization_options }.to change { Organization.count }
      expect(response).to redirect_to(invite_organization_path(Organization.last))
    end

    it 'will not add an organization that already exists' do
      existing_organization_options = { title: organization.title, github_id: organization.github_id }
      expect { post :create, organization: existing_organization_options }.to_not change { Organization.count }
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

  describe 'DELETE #destroy' do
    it 'deletes the organization' do
      expect { delete :destroy, id: organization.id }.to change { Organization.count }
    end

    it 'redirects back to the dashboard' do
      delete :destroy, id: organization.id
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'GET #invite', :vcr do
    it 'returns an array of organization admins that have not been added yet' do
      get :invite, id: organization.id

      expect(assigns(:organization_owners)).to be_kind_of(Array)
      expect(assigns(:organization_owners)).to_not include(user.uid)
    end
  end

  describe 'PATCH #invite_users', :vcr do
    it 'kicks off a InviteUserToClassroomJob for each invited user with an email address' do
      github_owner_emails_params  = { 'not_invited_owner' => '', 'invited_owner' => 'invited_owner.8675309@osu.edu' }
      github_owners_params        = { 'invited_owner' => '8439338' }

      patch :invite_users, id:                  organization.id,
                           github_owners:       github_owners_params,
                           github_owner_emails: github_owner_emails_params

      id    = github_owners_params['invited_owner']
      email = github_owner_emails_params['invited_owner']

      assert_enqueued_jobs 1 do
        InviteUserToClassroomJob.perform_later(id, email, user, organization)
      end
    end
  end
end
