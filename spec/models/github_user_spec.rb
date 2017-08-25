# frozen_string_literal: true

require "rails_helper"

describe GitHubUser do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  let(:github_user)       { GitHubUser.new(@client, @client.user.id) }
  let(:other_user)        { classroom_student                        }
  let(:other_github_user) { GitHubUser.new(@client, other_user.uid)  }

  it "responds to all (GitHub) attributes", :vcr do
    gh_user = github_user.client.user(github_user.id)

    github_user.attributes.each do |attribute, value|
      next if %i[client access_token].include?(attribute)
      expect(gh_user).to respond_to(attribute)
      expect(value).to eql(gh_user.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/user/#{gh_user.id}")).twice
  end

  it "responds to all *_no_cache methods", :vcr do
    github_user.attributes.each do |attribute, _|
      next if %i[id client access_token].include?(attribute)
      expect(github_user).to respond_to("#{attribute}_no_cache")
    end
  end

  describe "#github_avatar_url", :vcr do
    it "returns the correct url with a default size of 40" do
      expected_url = "https://avatars2.githubusercontent.com/u/#{github_user.id}?v=4&size=40"
      expect(github_user.github_avatar_url).to eql(expected_url)
    end

    it "has a customizeable size" do
      size         = 90
      expected_url = "https://avatars2.githubusercontent.com/u/#{github_user.id}?v=4&size=#{size}"

      expect(github_user.github_avatar_url(size)).to eql(expected_url)
    end
  end

  describe "#organization_memberships", :vcr do
    it "returns an array of organizations that the user belongs to" do
      organization_memberships = github_user.organization_memberships

      expect(WebMock).to have_requested(:get, github_url("/user/memberships/orgs?state=active"))
      expect(organization_memberships).to be_kind_of(Array)
    end
  end
end
