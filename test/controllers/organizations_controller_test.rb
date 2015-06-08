require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  before do
    @controller = OrganizationsController.new
    @org_login  = 'testorg'

    @user             = create(:user_with_organizations)
    session[:user_id] = @user.id
  end

  describe '#new' do
    before do
      @testorg1 = { login: 'testorg1', id: 1 }
      @testorg2 = { login: 'testorg2', id: 2 }

      stub_users_github_organizations([@testorg1, @testorg2])
    end

    it 'returns success' do
      get :new
      assert_response :success
    end

    it 'has a new organization' do
      get :new
      assert_not_nil assigns(:organization)
    end

    it 'has an array of the users GitHub organizations' do
      get :new
      assert_equal [[@testorg1[:login], @testorg1[:id]], [@testorg2[:login], @testorg2[:id]]], assigns(:users_github_organizations)
    end
  end

  describe '#create' do
    before do
      @testorg1 = { login: 'testorg1', id: 1 }
      @testorg2 = { login: 'testorg2', id: 2 }

      stub_users_github_organizations([@testorg1, @testorg2])
    end

    it 'will add an organization' do
      organization = build(:organization)

      stub_github_organization(organization.github_id, { login: @org_login, id: organization.github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'admin' })

      assert_difference 'Organization.count' do
        post :create, organization: { title: organization.title, github_id: organization.github_id }
      end

      assert_redirected_to organization_path(Organization.last)
    end

    it 'will not add an organization that already exists' do
      existing_organization = @user.organizations.first

      stub_github_organization(existing_organization.github_id, { login: @org_login, id: existing_organization.github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'admin' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title:     "#{existing_organization.title}",
                                      github_id: "#{existing_organization.github_id}" }
      end
    end

    it 'will only add the organization if the user is an administrator' do
      github_id = 1

      stub_github_organization(github_id, { login: @org_login, id: github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'member' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title: @org_login, github_id: github_id }
      end
    end
  end

  describe '#show' do
    before do
      @organization = @user.organizations.first

      stub_github_organization(@organization.github_id, { login: @org_login, id: @organization.github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'admin' })
    end

    it 'returns success and sets the organization' do
      get :show, id: @organization.id

      assert_response :success
      assert_not_nil assigns(:organization)
    end
  end

  describe '#edit' do
    before do
      @organization = @user.organizations.first

      stub_github_organization(@organization.github_id, { login: @org_login, id: @organization.github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'admin' })
    end

    it 'returns success and sets the organization' do
      get :edit, id: @organization.id

      assert_response :success
      assert_not_nil assigns(:organization)
    end
  end

  describe '#destroy' do
    before do
      @organization = @user.organizations.first

      stub_github_organization(@organization.github_id, { login: @org_login, id: @organization.github_id })
      stub_users_github_organization_membership(@org_login, { state: 'active', role: 'admin' })
    end

    it 'deletes the organization' do
      assert_difference 'Organization.count', -1 do
        delete :destroy, id: @organization.id
      end
    end

    it 'redirects back to the dashboard' do
      delete :destroy, id: @organization.id
      assert_redirected_to dashboard_path
    end
  end
end
