require 'test_helper'

class GitHubClientTest < ActiveSupport::TestCase
  def setup
    @admin_org  = { login: 'tarebytetestorg', id: 12_439_714, owners_team_id: 1_501_923 }
    @member_org = { login: 'education',       id:  6_667_880                            }

    @user       = { login: 'tarebyte',        id:   564_113 }
    @test_user  = { login: 'tarebytetest',    id: 12_435_329 }

    token          = Rails.application.secrets.classroom_test_github_token || 'some-token'
    @github_client = GitHubClient.new(token)
  end

  test '#add_team_membership' do
    VCR.use_cassette('add_team_membership') do
      membership = @github_client.add_team_membership(@admin_org[:owners_team_id], @test_user[:login])
      assert_requested :put, github_url("teams/#{@admin_org[:owners_team_id]}/memberships/#{@test_user[:login]}")
      assert 'pending', membership.status
    end
  end

  test '#create_repository' do
  end

  test '#create_team' do
    VCR.use_cassette('create_team') do
      @team_name = "Test Team #{Time.zone.now.to_i}"
      @team = @github_client.create_team(@admin_org[:id], name: @team_name)

      assert_requested :post, github_url("/organizations/#{@admin_org[:id]}/teams")
    end
  end

  test '#organization' do
    VCR.use_cassette('organization') do
      organization = @github_client.organization(@member_org[:id])

      assert @member_org[:login], organization.login
      assert_requested :get, github_url("/organizations/#{@member_org[:id]}")
    end
  end

  test '#organization_admin?' do
    VCR.use_cassette('admin_organization_membership') do
      assert @github_client.organization_admin?(@admin_org[:id])
      assert_requested :get, github_url("user/memberships/orgs/#{@admin_org[:login]}")
    end

    VCR.use_cassette('member_organization_membership') do
      assert_not @github_client.organization_admin?(@member_org[:id])
      assert_requested :get, github_url("user/memberships/orgs/#{@member_org[:login]}")
    end
  end

  test '#organization_teams' do
    VCR.use_cassette('organization_teams') do
      teams = @github_client.organization_teams(@member_org[:id])
      assert Array, teams.class
      assert_requested :get, github_url("/organizations/#{@member_org[:id]}/teams?per_page=100")
    end
  end

  test '#organization_membership' do
    VCR.use_cassette('organization_membership') do
      @github_client.organization_membership(@member_org[:login])
      assert_requested :get, github_url("/user/memberships/orgs/#{@member_org[:login]}")
    end
  end

  test '#organization_memberships' do
    VCR.use_cassette('organization_memberships') do
      @github_client.organization_memberships
      assert_requested :get, github_url('/user/memberships/orgs?per_page=100')
    end
  end

  test '#team' do
    VCR.use_cassette('team') do
      team = @github_client.team(@admin_org[:owners_team_id])

      assert @admin_org[:owners_team_id], team.id
      assert_requested :get, github_url("/teams/#{@admin_org[:owners_team_id]}")
    end
  end

  test '#team_repository?' do
    VCR.use_cassette('team_repository?') do
      is_team_repo = @github_client.team_repository?(@admin_org[:owners_team_id], "#{@admin_org[:login]}/notateamrepository")

      assert_not is_team_repo
      assert_requested :get, github_url("/teams/#{@admin_org[:owners_team_id]}/repos/#{@admin_org[:login]}/notateamrepository")
    end
  end

  test 'user' do
    VCR.use_cassette('user') do
      github_user   = @github_client.user(@test_user[:id])

      assert @test_user[:login], github_user.login
      assert_requested :get, github_url("/user/#{@test_user[:id]}")
    end

    VCR.use_cassette('user_self') do
      user = @github_client.user
      assert @user[:login], user.login
      assert_requested :get, github_url('/user')
    end
  end
end
