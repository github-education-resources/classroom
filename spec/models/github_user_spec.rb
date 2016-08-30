# frozen_string_literal: true
require 'rails_helper'

describe GitHubUser do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  let(:github_user)       { GitHubUser.new(@client, @client.user.id) }
  let(:other_user)        { GitHubFactory.create_classroom_student   }
  let(:other_github_user) { GitHubUser.new(@client, other_user.uid)  }

  describe '#github_avatar_url', :vcr do
    it 'returns the correct url with a default size of 40' do
      expected_url = "https://avatars.githubusercontent.com/u/#{github_user.id}?v=3&size=40"
      expect(github_user.github_avatar_url).to eql(expected_url)
    end

    it 'has a customizeable size' do
      size         = 90
      expected_url = "https://avatars.githubusercontent.com/u/#{github_user.id}?v=3&size=#{size}"

      expect(github_user.github_avatar_url(size)).to eql(expected_url)
    end
  end

  GitHubUser.new(@client, 123).send(:attributes).each do |attribute|
    describe "##{attribute}", :vcr do
      it "gets the #{attribute} of the user" do
        user = @client.user

        expect(github_user.send(attribute)).to eql(user.send(attribute))
        expect(WebMock).to have_requested(:get, github_url("/user/#{user.id}"))
      end
    end
  end

  describe '#organization_memberships', :vcr do
    it 'returns an array of organizations that the user belongs to' do
      organization_memberships = github_user.organization_memberships

      expect(WebMock).to have_requested(:get, github_url('/user/memberships/orgs?state=active'))
      expect(organization_memberships).to be_kind_of(Array)
    end
  end
end
