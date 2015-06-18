require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do
  let(:org_login) { 'test_org' }
  let(:user)      { create(:user_with_organizations) }

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
      @admin_org1  = { role: 'admin',  organization: { login: 'admin_org1',  id: 1 } }
      @admin_org2  = { role: 'admin',  organization: { login: 'admin_org2',  id: 2 } }
      @member_org1 = { role: 'member', organization: { login: 'member_org1', id: 3 } }

      @request_stubs << stub_users_github_organization_memberships([@admin_org1, @admin_org2, @member_org1])
    end

    it 'returns success status' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'has a new organization' do
      get :new
      expect(assigns(:organization)).to_not be_nil
    end

    it 'has an array of the users GitHub organizations that they are an admin of' do
      admin_array = [
        [@admin_org1[:organization][:login], @admin_org1[:organization][:id]],
        [@admin_org2[:organization][:login], @admin_org2[:organization][:id]]
      ]

      get :new
      expect(assigns(:users_github_organizations)).to eq(admin_array)
    end
  end

  describe 'POST #create' do
    before(:each) do
      @admin_org1  = { role: 'admin',  organization: { login: 'admin_org1',  id: 1 } }
      @admin_org2  = { role: 'admin',  organization: { login: 'admin_org2',  id: 2 } }
      @member_org1 = { role: 'member', organization: { login: 'member_org1', id: 3 } }

      @request_stubs << stub_users_github_organization_memberships([@admin_org1, @admin_org2, @member_org1])
    end

    it 'will add an organization' do
      organization = build(:organization)
      organization_options = { title: organization.title, github_id: organization.github_id }

      expect { post :create, organization: organization_options }.to change { Organization.count }
      expect(response).to redirect_to(organization_path(Organization.last))
    end

    it 'will not add an organization that already exists' do
      existing_organization = user.organizations.first

      organization_options = { title: existing_organization.title, github_id: existing_organization.github_id }
      expect { post :create, organization: organization_options }.to_not change { Organization.count }
    end
  end

  describe 'GET #show' do
    let(:organization) { user.organizations.first }

    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'returns success and sets the organization' do
      get :show, id: organization.id

      expect(response.status).to eq(200)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'GET #edit' do
    let(:organization) { user.organizations.first }

    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'returns success and sets the organization' do
      get :edit, id: organization.id

      expect(response).to have_http_status(:success)
      expect(assigns(:organization)).to_not be_nil
    end
  end

  describe 'PATCH #update' do
    let(:organization) { user.organizations.first }

    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'correctly updates the organization' do
      options = { title: 'New Title' }
      patch :update, id: organization.id, organization: options

      expect(response).to redirect_to(organization_path(organization))
    end
  end

  describe 'DELETE #destroy' do
    let(:organization) { user.organizations.first }

    before(:each) do
      @request_stubs << stub_github_organization(organization.github_id, login: org_login, id: organization.github_id)
      @request_stubs << stub_users_github_organization_membership(org_login, state: 'active', role: 'admin')
    end

    it 'deletes the organization' do
      expect { delete :destroy, id: organization.id }.to change { Organization.count }
    end

    it 'redirects back to the dashboard' do
      delete :destroy, id: organization.id
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
