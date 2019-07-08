# frozen_string_literal: true

require "rails_helper"

describe GitHubUser do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  let(:github_user)       { GitHubUser.new(@client, @client.user.id, classroom_resource: classroom_teacher ) }
  let(:other_user)        { classroom_student }
  let(:other_github_user) { GitHubUser.new(@client, other_user.uid, classroom_resource: other_user) }

  it "responds to all (GitHub) attributes", :vcr do
    gh_user = github_user.client.user(github_user.id)

    github_user.attributes.each do |attribute, value|
      next if %i[id_attributes client access_token].include?(attribute)
      expect(gh_user).to respond_to(attribute)
      expect(value).to eql(gh_user.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/user/#{gh_user.id}")).once
  end

  it "responds to all *_no_cache methods", :vcr do
    github_user.attributes.each do |attribute, _|
      next if %i[id id_attributes client access_token].include?(attribute)
      expect(github_user).to respond_to("#{attribute}_no_cache")
    end
  end

  describe "#github_avatar_url", :vcr do
    it "returns the correct url with a default size of 40" do
      expected_url = %r{https:\/\/avatars[0-9].githubusercontent.com\/u\/#{github_user.id}\?v=4&size=40\z}
      expect(github_user.github_avatar_url).to match(expected_url)
    end

    it "has a customizeable size" do
      size         = 90
      expected_url = %r{https:\/\/avatars[0-9].githubusercontent.com\/u\/#{github_user.id}\?v=4&size=#{size}\z}

      expect(github_user.github_avatar_url(size)).to match(expected_url)
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
