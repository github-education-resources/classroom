require 'test_helper'

class GitHubTeamTest < ActiveSupport::TestCase
  def setup
    @user         = create(:user_with_organizations)
    @organization = @user.organizations.first

    @team = { id: 8675309, name: 'Students' }
  end

  test '#find_or_create_team returns an existing team' do
    stub_json_request(:get,
                      github_url("/teams/#{@team[:id]}"),
                      @team)

    github_team = GitHubTeam.find_or_create_team(@user.github_client,
                                                 @organization.github_id,
                                                 @team[:id],
                                                 @team[:name])

    assert @team[:id],   github_team.id
    assert @team[:name], github_team.name
  end

  test '#find_or_create_team returns a new team' do
    stub_json_request(:get, github_url("/teams/"), nil)

    stub_json_request(:post,
                      github_url("/organizations/#{@organization.github_id}/teams"),
                      { name: @team[:name], permission: 'push'}.to_json,
                      @team)

    github_team = GitHubTeam.find_or_create_team(@user.github_client,
                                                 @organization.github_id,
                                                 nil,
                                                 @team[:name])

    assert @team[:id],   github_team.id
    assert @team[:name], github_team.name
  end

  test '#find_or_create_team returns NullGitHubTeam' do
    stub_json_request(:get, github_url("/teams/"), nil)

    stub_json_request(:post,
                      github_url("/organizations/#{@organization.github_id}/teams"),
                      { name: @team[:name], permission: 'push'}.to_json,
                      nil)

    github_team = GitHubTeam.find_or_create_team(@user.github_client,
                                                 @organization.github_id,
                                                 nil,
                                                 @team[:name])

    assert NullGitHubTeam, github_team.class
  end
end
