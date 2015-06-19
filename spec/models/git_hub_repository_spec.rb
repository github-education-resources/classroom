require 'rails_helper'

describe GitHubRepository do
  let(:default_repo_options) { { has_issues: true, has_wiki: true, has_downloads: true } }

  describe '#create_repository' do
    let(:user)      { create(:user) }
    let(:repo_name) { 'Team 1' }

    it 'successfully creates a new GitHub repository' do
      options = default_repo_options.merge(name: repo_name)
      stub_create_github_repository(options, id: 1)

      repo = GitHubRepository.create_repository(user, repo_name)
      expect(repo.id).to_not be_nil
    end

    it 'returns a NullGitHubRepository if there was an error' do
      options = default_repo_options.merge(name: nil)
      stub_create_github_repository(options, nil)

      repo = GitHubRepository.create_repository(user, nil)
      expect(repo.class).to be(NullGitHubRepository)
    end
  end

  describe 'github_repo_default_options' do
    it 'has the defaults for the repo' do
      expect(GitHubRepository.github_repo_default_options).to eq(default_repo_options)
    end
  end
end
