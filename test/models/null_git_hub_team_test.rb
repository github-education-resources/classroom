require 'test_helper'

class NullGitHubTeamTest < ActiveSupport::TestCase
  def setup
    @null_github_team = NullGitHubTeam.new
  end

  test '#id returns nil' do
    assert_nil @null_github_team.id
  end

  test '#name returns nil' do
    assert_nil @null_github_team.name
  end
end
