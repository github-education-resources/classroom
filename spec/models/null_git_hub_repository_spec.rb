require 'rails_helper'

describe NullGitHubRepository do
  it 'exposes the same public interface as GitHubRepository' do
    expect(described_class).to match_the_interface_of(GitHubRepository)
  end
end
