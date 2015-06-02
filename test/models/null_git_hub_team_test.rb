require 'test_helper'

class NullGitHubTeamTest < ActiveSupport::TestCase
  test 'has the same interface as GitHubTeam' do
    assert_matching_interface  GitHubTeam, NullGitHubTeam
  end
end
