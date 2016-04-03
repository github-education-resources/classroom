require 'rails_helper'

describe GitHubTeam do
  it_behaves_like 'a GitHubResource descendant with attributes'

  before do
    Octokit.reset!
  end

  let(:github_organization) { GitHubFactory.create_owner_classroom_org.github_organization }
  let(:github_student)      { GitHubFactory.create_classroom_student.github_user           }

  describe '#disabled?', :vcr do
    it 'returns true if the team is not present' do
      github_team = GitHubTeam.new(id: 8_675_309, access_token: github_organization.access_token)
      expect(github_team.disabled?).to be_truthy
    end
  end

  context 'with a GitHub team', :vcr do
    before(:each) do
      @github_team = github_organization.create_team(name: 'Team')
    end

    after(:each) do
      github_organization.delete_team(github_team: @github_team)
      github_organization.remove_organization_member(github_user: github_student)
    end

    context 'team membership' do
      let(:github_team_membership_url) { "teams/#{@github_team.id}/memberships/#{github_student.login}" }

      describe '#add_team_membership' do
        it 'adds a user to the given GitHubTeam' do
          @github_team.add_team_membership(github_user: github_student)
          expect(WebMock).to have_requested(:put, github_url(github_team_membership_url))
        end
      end

      context 'with team membership' do
        before(:each) do
          @github_team.add_team_membership(github_user: github_student)
        end

        it 'removes the user from the team' do
          @github_team.remove_team_membership(github_user: github_student)
          expect(WebMock).to have_requested(:delete, github_url(github_team_membership_url))
        end
      end
    end

    context 'with organization repository' do
      let(:request_url) { "/teams/#{@github_team.id}/repos/#{github_organization.login}/the-repo" }

      before(:each) do
        @repository = github_organization.create_repository(name: 'the repo', private: true)
      end

      after(:each) do
        github_organization.delete_repository(github_repository: @repository)
      end

      describe '#add_team_repository' do
        it 'adds a repository to the team' do
          @github_team.add_team_repository(github_repository: @repository)
          expect(WebMock).to have_requested(:put, github_url(request_url))
        end
      end
    end

    describe '#team' do
      it 'returns team the GitHub API' do
        team = @github_team.team

        expect(team).to be_instance_of(Sawyer::Resource)
        expect(team.id).to eql(@github_team.id)
      end
    end

    describe '#team_repository?' do
      it 'checks if a repo is managed by a specific team' do
        grit = GitHubRepository.new(id: 1, access_token: github_organization.access_token)

        is_team_repo = @github_team.team_repository?(github_repository: grit)
        url = "/teams/#{@github_team.id}/repos/#{grit.full_name}"

        expect(is_team_repo).to be false
        expect(WebMock).to have_requested(:get, github_url(url))
      end
    end
  end
end
