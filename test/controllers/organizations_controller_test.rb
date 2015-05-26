require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  before do
    @controller       = OrganizationsController.new
    session[:user_id] = users(:tobias).id
  end

  describe '#new' do
    before do
      stub_get_json(github_url('/user/orgs'),
                    [{ login: 'testorg1', id: 1 },
                     { login: 'testorg2', id: 2 }])
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
      assert_equal [['testorg1', 1], ['testorg2', 2]], assigns(:users_github_organizations)
    end
  end

  describe '#create' do
    before do
      stub_get_json(github_url('/user/orgs'),
                    [{ login: 'testorg1', id: 1 },
                     { login: 'testorg2', id: 2 }])
    end

    it 'will add an organization' do
      stub_get_json(github_url('/organizations/1'),
                    { login: 'testorg1',
                      id: 1 })

      stub_get_json(github_url('/user/memberships/orgs/testorg1'),
                    { state: 'active',
                      role:  'admin' })

      assert_difference 'Organization.count' do
        post :create, organization: { title: 'Test Org One', github_id: 1 }
      end

      assert_redirected_to organization_path(Organization.last)
    end

    it 'will not add an organization that already exists' do
      existing_organization = organizations(:org1)

      stub_get_json(github_url("/organizations/#{existing_organization.github_id}"),
                    { login: 'org1',
                      id: existing_organization.github_id })

      stub_get_json(github_url("user/memberships/orgs/#{existing_organization.title}"),
                    { state: 'active',
                      role:  'admin' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title: "#{existing_organization.title}",
                                      github_id: "#{existing_organization.github_id}" }
      end
    end

    it 'will only add the organization if the user is an administrator' do
      stub_get_json(github_url('/organizations/1'),
                    { login: 'testorg1',
                      id: 1 })

      stub_get_json(github_url('/user/memberships/orgs/testorg1'),
                    { state: 'active',
                      role:  'member' })

      assert_no_difference 'Organization.count' do
        post :create, organization: { title: 'Test Org One', github_id: 1 }
      end
    end
  end

  describe '#show' do
    before do
      @organization = organizations(:org1)

      stub_get_json(github_url("/organizations/#{@organization.github_id}"),
                    { login: 'org1',
                      id: @organization.github_id })

      stub_get_json(github_url('/user/memberships/orgs/org1'),
                    { state: 'active',
                      role:  'admin' })
    end

    it 'returns success and sets the organization' do
      get :show, id: @organization.id

      assert_response :success
      assert_not_nil assigns(:organization)
    end
  end

  describe '#edit' do
    before do
      @organization = organizations(:org1)

      stub_get_json(github_url("/organizations/#{@organization.github_id}"),
                    { login: 'org1',
                      id: @organization.github_id })

      stub_get_json(github_url('/user/memberships/orgs/org1'),
                    { state: 'active',
                      role:  'admin' })
    end

    it 'returns success and sets the organization' do
      get :edit, id: organizations(:org1).id

      assert_response :success
      assert_not_nil assigns(:organization)
    end
  end


  describe '#destroy' do
    before do
      @organization = organizations(:org1)

      stub_get_json(github_url("/organizations/#{@organization.github_id}"),
                    { login: 'org1',
                      id: @organization.github_id })

      stub_get_json(github_url('/user/memberships/orgs/org1'),
                    { state: 'active',
                      role:  'admin' })
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
