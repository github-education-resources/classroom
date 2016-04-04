require 'rails_helper'

describe GitHubUser do
  it_behaves_like 'a GitHubResource descendant with attributes'

  before do
    Octokit.reset!
  end

  context 'with GitHub user', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:github_user) do
      user = organization.users.first
      user.github_user
    end

    let(:other_github_user) do
      other_user = GitHubFactory.create_classroom_student
      other_user.github_user
    end

    describe '#accept_membership_to' do
    end

    describe '#active_admin?' do
      it 'verifies if the user is an admin of the organization' do
        expect(github_user.active_admin?(github_organization: organization.github_organization)).to be_truthy
      end
    end

    describe '#client_scopes' do
      it 'returns an Array of scopes' do
        expect(github_user.client_scopes).to eq(%w(admin:org delete_repo repo user:email))
      end
    end

    describe '#disabled?' do
      it 'returns true if the user is not present' do
        missing_github_user = GitHubUser.new(id: 1_000_000_000, access_token: github_user.access_token)
        expect(missing_github_user.disabled?).to be_truthy
      end
    end

    describe '#organization_memberships', :vcr do
      it 'returns an array of organizations that the user belongs to' do
        organization_memberships = github_user.organization_memberships

        expect(WebMock).to have_requested(:get, github_url('/user/memberships/orgs?per_page=100&state=active'))
        expect(organization_memberships).to be_kind_of(Array)
      end
    end
  end
end
