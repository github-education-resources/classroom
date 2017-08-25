# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }

  subject { create(:user) }

  describe "#assign_from_auth_hash", :vcr do
    it "updates the users attributes" do
      subject.assign_from_auth_hash(github_omniauth_hash)
      expect(github_omniauth_hash.credentials.token).to eq(subject.token)
    end
  end

  describe "#create_from_auth_hash" do
    it "creates a valid user" do
      expect { User.create_from_auth_hash(github_omniauth_hash) }.to change(User, :count)
    end
  end

  describe "#find_by_auth_hash" do
    it "finds the correct user" do
      build(:user).assign_from_auth_hash(github_omniauth_hash)
      located_user = User.find_by_auth_hash(github_omniauth_hash)

      expect(located_user).to eq(User.last)
    end
  end

  describe "#flipper_id" do
    it "should return an id" do
      expect(subject.flipper_id).to eq("User:#{subject.id}")
    end
  end

  describe "#github_client" do
    it "sets or creates a new GitHubClient with the users token" do
      expect(subject.github_client.class).to eql(Octokit::Client)
    end
  end

  describe "#github_user", :vcr do
    subject { classroom_student }

    it "sets or creates a new GitHubUser with the users uid" do
      expect(subject.github_user.class).to eql(GitHubUser)
      expect(subject.github_user.id).to eql(subject.uid)
    end
  end

  describe "#staff?" do
    it "returns if the User is a site_admin" do
      expect(subject.staff?).to be(false)
      subject.update_attributes(site_admin: true)
      expect(subject.staff?).to be(true)
    end
  end

  describe "#github_client_scopes", :vcr do
    it "returns an Array of scopes" do
      subject.assign_from_auth_hash(github_omniauth_hash)
      scopes = subject.github_client_scopes

      %w[write:org read:org admin:org_hook delete_repo repo:status repo_deployment public_repo repo:invite user:email].each do |s| # rubocop:disable Metrics/LineLength
        expect(scopes).to include(s)
      end
    end
  end

  describe "tokens", :vcr do
    let(:student) { classroom_student }

    it "does not allow a User to lose their token scope" do
      good_token = student.token
      bad_token  = "e72e16c7e42f292c6912e7710c838347ae178b4a"

      student.update_attributes(token: bad_token)

      expect(student.token).to eql(good_token)
    end
  end
end
