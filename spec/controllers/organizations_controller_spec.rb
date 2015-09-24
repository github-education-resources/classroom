require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index', :vcr do
    context 'unauthenticated user' do
      before do
        session[:user_id] = nil
      end

      it 'redirects to login_path' do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end

    context 'authenticated user with a valid token' do
      it 'succeeds' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'sets the users organization' do
        get :index
        expect(assigns(:organizations).first.id).to eq(organization.id)
      end
    end

    context 'authenticated user with an invalid token' do
      before do
        user.token = '12345'
        user.save!
      end

      it 'redirects to login_path' do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
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
    before do
      request.env['HTTP_REFERER'] = 'http://classroomtest.com/orgs/new'
    end

    it 'will fail to add an organization the user is not an admin of' do
      new_organization = build(:organization, github_id: 90)
      new_organization_options = { title: new_organization.title, github_id: new_organization.github_id }

      expect { post :create, organization: new_organization_options }.not_to change { Organization.count }
    end

    it 'will not add an organization that already exists' do
      existing_organization_options = { title: organization.title, github_id: organization.github_id }
      expect { post :create, organization: existing_organization_options }.to_not change { Organization.count }
    end

    it 'will add an organization that the user is admin of on GitHub' do
      organization_params = { title: organization.title, github_id: organization.github_id, users: organization.users }
      organization.destroy!

      expect { post :create, organization: organization_params }.to change { Organization.count }
    end
  end

  describe 'GET #show', :vcr do
    it 'returns success and sets the organization' do
      get :show, id: organization.id

      expect(response.status).to eq(200)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'GET #edit', :vcr do
    it 'returns success and sets the organization' do
      get :edit, id: organization.id

      expect(response).to have_http_status(:success)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'PATCH #update', :vcr do
    it 'correctly updates the organization' do
      options = { title: 'New Title' }
      patch :update, id: organization.id, organization: options

      expect(response).to redirect_to(organization_path(organization))
    end
  end

  describe 'DELETE #destroy', :vcr do
    it 'sets the `deleted_at` column for the organization' do
      expect { delete :destroy, id: organization.id }.to change { Organization.all.count }
      expect(Organization.unscoped.find(organization.id).deleted_at).not_to be_nil
    end

    it 'calls the DestroyResource background job' do
      delete :destroy, id: organization.id

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(organization)
      end
    end

    it 'redirects back to the index page' do
      delete :destroy, id: organization.id
      expect(response).to redirect_to(organizations_path)
    end
  end

  describe 'GET #invite', :vcr do
    it 'returns success and sets the organization' do
      get :invite, id: organization.id

      expect(response.status).to eq(200)
      expect(assigns(:organization)).to_not be_nil
    end
  end
end
