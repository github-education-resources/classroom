require 'test_helper'

class GitHubTeamTest < ActiveSupport::TestCase
  def setup
    user         = create(:user_with_organizations)
    organization = user.organizations.first
    @github_team = GitHubTeam.new(user.github_client, organization.github_id)
  end

  test '#find_or_create_team returns an existing team' do

  end

  test '#find_or_create_team returns a new team' do

  end

  test '#find_or_create_team returns a GitHub::Null::Team object if there was an error' do

  end
end
