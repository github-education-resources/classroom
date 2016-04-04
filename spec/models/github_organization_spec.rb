require 'rails_helper'

describe GitHubOrganization do
  it_behaves_like 'a GitHubResource descendant with attributes'

  before do
    Octokit.reset!
  end

  context 'with GitHub Organization', :vcr do
    let(:organization)        { GitHubFactory.create_owner_classroom_org }
    let(:github_organization) { organization.github_organization }
    let(:repo_name)           { 'test-github-repository' }

    subject { organization.github_organization }

    describe '#add_membership' do
    end

    context 'with GitHub repository' do
      before(:each) do
        @github_repository = subject.create_repository(name: repo_name, private: true)
      end

      after(:each) do
        subject.delete_repository(github_repository: @github_repository)
      end

      describe '#create_repository', :vcr do
        it 'successfully creates a GitHub Repository for the Organization' do
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{subject.id}/repos"))
        end
      end

      describe '#delete_repository' do
        it 'successfully creates a GitHub Repository for the Organization' do
          github_organization.delete_repository(github_repository: @github_repository)
          url = "/repositories/#{@github_repository.id}"
          expect(WebMock).to have_requested(:delete, github_url(url))
        end
      end
    end

    context 'with GitHub team' do
      before(:each) do
        @github_team = subject.create_team(name: 'Team')
      end

      after(:each) do
        subject.delete_team(github_team: @github_team)
      end

      describe '#create_team' do
        it 'successfully creates a GitHub team' do
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{subject.id}/teams"))
        end
      end

      describe '#delete_team' do
        it 'successfully deletes a GitHub team' do
          subject.delete_team(github_team: @github_team)
          expect(WebMock).to have_requested(:delete, github_url("/teams/#{@github_team.id}"))
        end
      end
    end

    describe '#disabled?' do
      it 'returns true if the organization is not present' do
        github_organization = GitHubOrganization.new(id: 1, access_token: subject.access_token)
        expect(github_organization.disabled?).to be_truthy
      end
    end

    describe '#member?' do
      context 'user is not a member' do
        let(:non_member) { GitHubUser.new(id: 2, access_token: subject.access_token) }

        it 'returns false' do
          expect(subject.member?(github_user: non_member)).to be_falsey
        end
      end

      context 'user is a member' do
        let(:member) do
          id = organization.users.first.uid
          GitHubUser.new(id: id, access_token: subject.access_token)
        end

        it 'returns true' do
          expect(subject.member?(github_user: member)).to be_truthy
        end
      end
    end

    describe '#organization' do
      it 'returns the correct organization from the GitHub API' do
        expect(subject.organization.id).to eql(subject.id)
      end
    end

    describe '#plan' do
      it 'gets the plan for an organization' do
        expect(github_organization.plan[:owned_private_repos]).not_to be_nil
        expect(github_organization.plan[:private_repos]).not_to be_nil
      end

      it 'fails for an org that the token is not authenticated for' do
        unauthorized_github_organization = GitHubOrganization.new(id: 9919, access_token: organization.access_token)
        expect { unauthorized_github_organization.plan }.to raise_error(GitHub::Error)
      end
    end

    context 'with GitHub organization member' do
      let(:github_student) { GitHubFactory.create_classroom_student.github_user }

      before do
        subject.add_membership(github_user: github_student)
        github_student.accept_membership_to(github_organization: subject)
      end

      describe '#remove_member' do
        it 'removes the member from the organization' do
          subject.remove_member(member: github_student)

          url = "/organizations/#{subject.id}/members/#{github_student.login}"
          expect(WebMock).to have_requested(:delete, github_url(url))
        end
      end
    end
  end
end
