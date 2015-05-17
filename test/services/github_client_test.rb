require 'test_helper'

class GithubClientTest < ActiveSupport::TestCase
  def setup
    token = Rails.application.secrets.classroom_test_github_token || 'some-token'
    @github_client = GithubClient.new('tarebyte', token)
  end

  test '#is_organization_admin?' do
    VCR.use_cassette('admin_organization_membership') do
      assert @github_client.is_organization_admin?('boxen')
      assert :get, github_url('user/memberships/orgs/boxen')
    end

    VCR.use_cassette('member_organization_membership') do
      assert_not @github_client.is_organization_admin?('education')
      assert :get, github_url('user/memberships/orgs/education')
    end
  end

  test '#organization returns a single organization for a user' do
    VCR.use_cassette('organization') do
      organization = @github_client.organization('education')

      assert 'education', organization.login
      assert_requested :get, github_url('/orgs/education')
    end
  end

  test '#users_organizations returns all organizations for a user' do
    VCR.use_cassette('list_organizations') do
      organizations = @github_client.users_organizations

      assert Array, organizations.class
      assert_requested :get, github_url('/users/tarebyte/orgs')
    end
  end
end
