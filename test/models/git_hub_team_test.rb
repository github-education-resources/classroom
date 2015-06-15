require 'test_helper'

class GitHubTeamTest < ActiveSupport::TestCase
  def setup
    @user         = create(:user_with_organizations)
    @organization = @user.organizations.first

    @team = { id: 8_675_309, name: 'Students' }
  end

  test '#add_user_to_team' do
  end

  test '#create_team returns a new team' do
    stub_github_team(nil, nil)

    stub_create_github_team(@organization.github_id, { name: @team[:name], permission: 'push' }, @team)

    github_team = GitHubTeam.create_team(@user, @organization.github_id, @team[:name])

    assert @team[:id],   github_team.id
    assert @team[:name], github_team.name
  end

  test '#create_team returns NullGitHubTeam' do
    stub_github_team(nil, nil)

    stub_create_github_team(@organization.github_id, { name: @team[:name], permission: 'push' }, nil)

    github_team = GitHubTeam.create_team(@user, @organization.github_id, @team[:name])

    assert NullGitHubTeam, github_team.class
  end
end
