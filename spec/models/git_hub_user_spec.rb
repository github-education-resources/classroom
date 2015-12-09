require 'rails_helper'

describe GitHubUser do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  let(:github_user)       { GitHubUser.new(@client, @client.user.id) }
  let(:other_user)        { GitHubFactory.create_classroom_student   }
  let(:other_github_user) { GitHubUser.new(@client, other_user.uid)  }

  describe '#login', :vcr do
    it 'gets the login of the user' do
      expect(github_user.login).to eql(@client.user.login)
    end

    it 'gets the login of another user' do
      expect(other_github_user.login).to eql(@client.user(other_user.uid).login)
    end
  end

  describe '#organization_memberships', :vcr do
    it 'returns an array of organizations that the user belongs to' do
      organization_memberships = github_user.organization_memberships

      expect(WebMock).to have_requested(:get, github_url('/user/memberships/orgs?state=active'))
      expect(organization_memberships).to be_kind_of(Array)
    end
  end

  describe '#user', :vcr do
    it 'gets the client users info' do
      expect(github_user.user.id).to eql(@client.user.id)
    end

    it 'gets another users info' do
      expect(other_github_user.user.id).to eql(@client.user(other_user.uid).id)
    end
  end
end
