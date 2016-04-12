require 'rails_helper'

describe GitHub::URL do
  subject { described_class }

  describe '#avatar' do
    it 'returns the correct with with a default size of 40' do
      avatar_url = 'https://avatars.githubusercontent.com/u/1?v=3&size=40'
      expect(subject.avatar(id: 1)).to eql(avatar_url)
    end

    it 'returns the correct url with a size of 80' do
      avatar_url = 'https://avatars.githubusercontent.com/u/1?v=3&size=80'
      expect(subject.avatar(id: 1, size: 80)).to eql(avatar_url)
    end
  end

  context 'with a GitHub organization', :vcr do
    let(:github_organization) { GitHubFactory.create_owner_classroom_org.github_organization }

    describe '#github_organization_team_invitation' do
      it 'returns the correct url' do
        expected_url = "https://github.com/orgs/#{github_organization.login}/invitations/new"
        actual_url = subject.github_organization_team_invitation(github_organization: github_organization)

        expect(actual_url).to eql(expected_url)
      end
    end

    context 'with a GitHub team', :vcr do
      before(:each) do
        @github_team = github_organization.create_team(name: 'The A Team')
      end

      after(:each) do
        github_organization.delete_team(github_team: @github_team)
      end

      describe '#github_team' do
        it 'returns the correct url' do
          expected_url = "https://github.com/orgs/#{github_organization.login}/teams/#{@github_team.slug}"
          actual_url = subject.github_team(github_organization: github_organization, github_team: @github_team)

          expect(actual_url).to eql(expected_url)
        end
      end
    end
  end
end
