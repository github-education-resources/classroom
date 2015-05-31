require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  before do
    @controller = OrganizationsController.new
    @org_login  = 'testorg'
  end

  describe '#new' do
    before do
      session[:user_id] = create(:user).id

      @testorg1 = { login: 'testorg1', id: 1 }
      @testorg2 = { login: 'testorg2', id: 2 }

      stub_json_request(:get,
                        github_url('/user/orgs'),
                        [@testorg1, @testorg2])
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
      @user = create(:user_with_organizations)
      session[:user_id] = create(:user).id

      @testorg1 = { login: 'testorg1', id: 1 }
      @testorg2 = { login: 'testorg2', id: 2 }

      stub_json_request(:get,
                        github_url('/user/orgs'),
                        [@testorg1, @testorg2])
    end

    it 'will add an organization' do
      organization = build(:organization)

      stub_json_request(:get,
                        github_url("/organizations/#{organization.github_id}"),
                        { login: @org_login, id: organization.github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'admin' })

      assert_difference 'Organization.count' do
        post :create, organization: { title: organization.title, github_id: organization.github_id }
      end

      assert_redirected_to invite_organization_path(Organization.last)
    end

    it 'will not add an organization that already exists' do
      existing_organization = @user.organizations.first

      stub_json_request(:get,
                        github_url("/organizations/#{existing_organization.github_id}"),
                        { id: existing_organization.github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'admin' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title:     "#{existing_organization.title}",
                                      github_id: "#{existing_organization.github_id}" }
      end
    end

    it 'will only add the organization if the user is an administrator' do
      github_id = 1
      title     = 'Test Org'

      stub_json_request(:get,
                        github_url("/organizations/#{github_id}"),
                        { login: @org_login, id: github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'member' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title: title, github_id: github_id }
      end
    end
  end

  describe '#show' do
    before do
      @user         = create(:user_with_organizations)
      @organization = @user.organizations.first

      session[:user_id] = @user.id

      stub_json_request(:get,
                        github_url("/organizations/#{@organization.github_id}"),
                        { login: @org_login, id: @organization.github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'admin' })
    end

    it 'it redirects to the invite page if the invitation is not set' do
      get :show, id: @organization.id

      assert_redirected_to invite_organization_path(@organization)
      assert_not_nil assigns(:organization)
    end

    it 'sets the invitation if present' do
      invitation   = create(:invitation)
      organization = invitation.organization

      session[:user_id] = invitation.user.id

      get :show, id: @organization.id
    end
  end

  describe '#edit' do
    before do
      invitation    = create(:invitation)

      @user         = invitation.user
      @organization = invitation.organization

      session[:user_id] = @user.id

      stub_json_request(:get,
                        github_url("/organizations/#{@organization.github_id}"),
                        { login: @org_login, id: @organization.github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'admin' })
    end

    it 'returns success and sets the organization' do
      get :edit, id: @organization.id

      assert_response :success
      assert_not_nil assigns(:organization)
    end
  end

  describe '#destroy' do
    before do
      invitation    = create(:invitation)
      @organization = invitation.organization
      @user         = invitation.user

      session[:user_id] = @user.id

      stub_json_request(:get,
                        github_url("/organizations/#{@organization.github_id}"),
                        { login: @org_login, id: @organization.github_id })

      stub_json_request(:get,
                        github_url("/user/memberships/orgs/#{@org_login}"),
                        { state: 'active', role: 'admin' })
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
