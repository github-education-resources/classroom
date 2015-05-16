require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  def setup
    @user             = users(:tobias)
    session[:user_id] = @user.id
  end

  test '#new returns success' do
    stub_get_json("https://api.github.com/users/#{@user.login}/orgs",
                  [{ login: 'testorg1', id: 1 },
                   { login: 'testorg2', id: 2 }])

    get :new
    assert_response :success
  end

  test '#new has a new organization' do
    stub_get_json("https://api.github.com/users/#{@user.login}/orgs",
                  [{ login: 'testorg1', id: 1 },
                   { login: 'testorg2', id: 2 }])

    get :new
    assert_not_nil assigns(:organization)
  end

  test '#new has an array of github organizations' do
    stub_get_json("https://api.github.com/users/#{@user.login}/orgs",
                  [{ login: 'testorg1', id: 1 },
                   { login: 'testorg2', id: 2 }])

    get :new
    assert_equal [['testorg1', ['testorg1', 1]], ['testorg2', ['testorg2', 2]]],
                 assigns(:users_github_organizations)
  end

  test '#create will add an organization' do
    stub_get_json("https://api.github.com/user/memberships/orgs/testorg1",
                  { url: "https://api.github.com/orgs/testorg1/memberships/#{@user.login}",
                    state: 'active',
                    role:  'admin' })

    assert_difference 'Organization.count', 1 do
      post :create, org: ['testorg1', 1].to_json
    end
  end

  test '#create will not add an organization that already exists' do
    existing_organization = organizations(:org1)
    stub_get_json("https://api.github.com/user/memberships/orgs/#{existing_organization.login}",
                  { url: "https://api.github.com/orgs/testorg1/memberships/#{@user.login}",
                    state: 'active',
                    role:  'admin' })

    assert_no_difference 'Organization.count' do
      post :create, org: ["#{existing_organization.login}",
                          "#{existing_organization.github_id}"].to_json
    end

  end

  test '#create will not add an organization that the users is not and admin for' do
    stub_get_json("https://api.github.com/user/memberships/orgs/testorg1",
                  { url: "https://api.github.com/orgs/testorg1/memberships/#{@user.login}",
                    state: 'active',
                    role:  'member' })

    assert_no_difference 'Organization.count' do
      post :create, org: ['testorg1', 1].to_json
    end
  end

  test '#show returns success and sets the organization' do
    get :show, id: organizations(:org1).id

    assert_response :success
    assert_not_nil assigns(:organization)
  end

  test '#destroy deletes the organization' do
    assert_difference 'Organization.count', -1 do
      delete :destroy, id: organizations(:org1).id
    end
  end

  test '#destroy redirects back to the dashboard with a flash message' do
    delete :destroy, id: organizations(:org1).id

    assert_redirected_to dashboard_path
    assert_equal 'Classroom was successfully deleted', flash[:success]
  end
end
