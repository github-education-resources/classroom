require 'test_helper'

class GithubClientTest < ActiveSupport::TestCase
  def setup
    @github_boxen_id     = 1800808
    @github_education_id = 6667880

    token = Rails.application.secrets.classroom_test_github_token || 'some-token'
    @github_client = GithubClient.new(token)
  end

  test '#add_team_membership' do
    VCR.use_cassette('add_team_membership') do
      membership = @github_client.add_team_membership(1525065, 'tarebyte')
      assert_requested :put, github_url("teams/1525065/memberships/tarebyte")
      assert 'active', membership.status
    end
  end

  test '#organization_admin?' do
    VCR.use_cassette('admin_organization_membership') do
      assert @github_client.organization_admin?(@github_boxen_id)
      assert_requested :get, github_url('user/memberships/orgs/boxen')
    end

    VCR.use_cassette('member_organization_membership') do
      assert_not @github_client.organization_admin?(@github_education_id)
      assert_requested :get, github_url('user/memberships/orgs/education')
    end
  end

  test '#organization' do
    VCR.use_cassette('organization') do
      organization = @github_client.organization(@github_education_id)

      assert 'education', organization.login
      assert_requested :get, github_url("/organizations/#{@github_education_id}")
    end
  end

  test '#organization_teams' do
    VCR.use_cassette('organization_teams') do
      cwdg_org = 1033302
      teams = @github_client.organization_teams(cwdg_org)
      assert Array, teams.class
      assert_requested :get, github_url("/organizations/#{cwdg_org}/teams?per_page=100")
    end
  end

  test 'team' do
    VCR.use_cassette('team') do
      puppet_sublime_text_maintainers_id = 826537
      team = @github_client.team(puppet_sublime_text_maintainers_id)

      assert puppet_sublime_text_maintainers_id, team.id
      assert_requested :get, github_url("/teams/#{puppet_sublime_text_maintainers_id}")
    end
  end

  test 'user' do
    VCR.use_cassette('user') do
      tarebyte_test = {login: 'tarebytetest', id: 12435329}
      github_user   = @github_client.user(tarebyte_test[:id])

      assert tarebyte_test[:login], github_user.login
      assert_requested :get, github_url("/user/#{tarebyte_test[:id]}")
    end

    VCR.use_cassette('user_self') do
      user = @github_client.user
      assert 'tarebyte', user.login
      assert_requested :get, github_url('/user')
    end
  end

  test '#users_organizations' do
    VCR.use_cassette('list_organizations') do
      organizations = @github_client.users_organizations

      assert Array, organizations.class
      assert_requested :get, github_url('/user/orgs')
    end
  end
end
