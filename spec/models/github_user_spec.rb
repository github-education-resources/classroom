# frozen_string_literal: true

require "rails_helper"

describe GitHubUser do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  let(:user)              { classroom_teacher }
  let(:github_user)       { GitHubUser.new(@client, @client.user.id, classroom_resource: user) }
  let(:other_user)        { classroom_student }
  let(:other_github_user) { GitHubUser.new(@client, other_user.uid, classroom_resource: other_user) }

  it "responds to all locally cached GitHub attributes", :vcr do
    attributes = github_user.send(:local_cached_attributes)

    attributes.each do |attribute|
      expect(github_user).to respond_to(attribute)
    end

    expect(WebMock).not_to have_requested(:get, github_url("/user/#{github_user.id}"))
  end

  context "locally cached attributes", :vcr do
    context "when use_cache is true" do
      context "when cache is not warm" do
        before(:each) do
          user.update_attributes(github_login: nil, github_name: nil)
        end

        it "makes an API request" do
          expect(github_user.login).to_not be_nil
          expect(WebMock).to have_requested(:get, github_url("/user/#{github_user.id}")).once
        end

        it "populates the cache" do
          expect(user.github_login).to be_nil

          github_user.login

          expect(user.github_login).to_not be_nil
        end

        it "also populates other cached fields" do
          expect(user.github_name).to be_nil

          github_user.login

          expect(user.github_name).to_not be_nil
        end
      end

      context "when cache is warm" do
        before do
          user.update_attribute(:github_login, "login")
        end

        it "does not make an API request and returns the cached value" do
          expect(github_user.login).to eq("login")
          expect(WebMock).to_not have_requested(:get, github_url("/user/#{github_user.id}"))
        end
      end
    end

    context "when use_cache is false" do
      it "makes an API request, even when cache is populated" do
        user.update_attribute(:github_login, "login")
        expect(github_user.login(use_cache: false)).to_not eq("login")
        expect(WebMock).to have_requested(:get, github_url("/user/#{github_user.id}"))
      end
    end
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
