require 'rails_helper'

describe GitHub::Search do
  let(:user) { GitHubFactory.create_classroom_student }

  subject { described_class.new(user.token, user.uid) }

  describe '#search_github_repositories', :vcr do
    context 'search parameters are not defined' do
      it 'queries the users repositories' do
        search_url = "/user/#{user.uid}/repos?page=1&per_page=10&sort=updated"
        subject.search_github_repositories('')
        expect(WebMock).to have_requested(:get, github_url(search_url))
      end

      it 'returns a subset of repos that the user has access to' do
        repos, _error_message = subject.search_github_repositories('')

        repo_ids = repos.map(&:id).to_set
        expect_repo_ids = user.github_client.repos.map(&:id).to_set

        expect(repo_ids).to be_subset(expect_repo_ids)
      end
    end

    context 'search parameters are defined' do
      it 'queries the github repo search api' do
        search_url = 'search/repositories?page=1&per_page=10&q=rails%20in:name%20fork:true%20user:rails&sort=updated'
        subject.search_github_repositories('rails/rails')

        expect(WebMock).to have_requested(:get, github_url(search_url))
      end

      it 'returns search results of a query' do
        returned_repos, _error_message = subject.search_github_repositories('rails/rails')

        returned_repo_ids = returned_repos.map(&:id).to_set
        actual_repo_ids = user
                          .github_client
                          .search_repos('rails user:rails fork:true')[:items]
                          .map(&:id).to_set

        expect(returned_repo_ids).to be_subset(actual_repo_ids)
      end
    end
  end
end
