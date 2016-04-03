require 'rails_helper'

describe GitHubRepository do
  it_behaves_like 'a GitHubResource descendant with attributes'

  before do
    Octokit.reset!
  end

  context 'with GitHub repository', :vcr do
    let(:github_organization) { GitHubFactory.create_owner_classroom_org.github_organization }
    let(:github_user)         { GitHubFactory.create_classroom_student.github_user           }

    before(:each) do
      @github_repository = github_organization.create_repository(name: 'test-repository', private: true)
    end

    after(:each) do
      github_organization.delete_repository(github_repository: @github_repository)
    end

    describe '#add_collaborator' do
      it 'adds the user as an outside collaborator' do
        @github_repository.add_collaborator(github_user: github_user)

        collab_url = "https://api.github.com/repositories/#{@github_repository.id}/collaborators/#{github_user.login}"
        expect(WebMock).to have_requested(:put, github_url(collab_url))
      end
    end

    describe '#disabled?' do
      it 'returns true if the repository cannot be found' do
        github_repository = GitHubRepository.new(id: 3, access_token: github_organization.access_token)
        expect(github_repository.disabled?).to be_truthy
      end
    end

    describe '#get_starter_code_from' do
      it 'starts the importing of code from one repo to another' do
        starter_code = GitHubRepository.new(id: 1_062_897, access_token: github_organization.access_token)
        @github_repository.get_starter_code_from(source: starter_code)

        import_url = "https://api.github.com/repositories/#{@github_repository.id}/import"
        expect(WebMock).to have_requested(:put, github_url(import_url))
      end
    end

    describe '#repository', :vcr do
      it 'returns the correct repository' do
        github_repository = @github_repository.repository
        expect(github_repository.id).to eql(@github_repository.id)
      end
    end
  end
end
