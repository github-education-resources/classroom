require 'test_helper'

class GithubClientTest < ActiveSupport::TestCase
  def setup
    @github_boxen_id     = 1800808
    @github_education_id = 6667880

    token = Rails.application.secrets.classroom_test_github_token || 'some-token'
    @github_client = GithubClient.new(token)
  end

  test '#is_organization_admin?' do
    VCR.use_cassette('admin_organization_membership') do
      assert @github_client.is_organization_admin?(@github_boxen_id)
      assert :get, github_url('user/memberships/orgs/boxen')
    end

    VCR.use_cassette('member_organization_membership') do
      assert_not @github_client.is_organization_admin?(@github_education_id)
      assert :get, github_url('user/memberships/orgs/education')
    end
  end

  test '#organization returns a single organization for a user' do
    VCR.use_cassette('organization') do
      organization = @github_client.organization(@github_education_id)

      assert 'education', organization.login
      assert_requested :get, github_url("/organizations/#{@github_education_id}")
    end
  end

  test '#users_organizations returns all organizations for a user' do
    VCR.use_cassette('list_organizations') do
      organizations = @github_client.users_organizations

      assert Array, organizations.class
      assert_requested :get, github_url('/user/orgs')
    end
  end
end
