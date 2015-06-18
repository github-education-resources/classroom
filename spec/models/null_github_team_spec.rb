require 'rails_helper'

describe NullGitHubTeam do
  it 'exposes the same public interface as GitHubTeam' do
    expect(described_class).to match_the_interface_of(GitHubTeam)
  end
end
