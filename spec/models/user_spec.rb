# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { create(:user) }

  let(:github_omniauth_hash)  { OmniAuth.config.mock_auth[:github] }
  let(:user)                  { subject }

  describe ".search" do
    let(:searchable_user) { create(:user, github_login: "d12", github_name: "Nathaniel Woodthorpe", uid: 123_999) }

    before do
      expect(searchable_user).to_not be_nil
    end

    it "searches by github_login" do
      results = User.search("d12")
      expect(results.to_a).to include(searchable_user)
    end

    it "searches by github_name" do
      results = User.search("Nathaniel")
      expect(results.to_a).to include(searchable_user)
    end

    it "searches by uid" do
      results = User.search(searchable_user.uid)
      expect(results.to_a).to include(searchable_user)
    end

    it "searches by id" do
      results = User.search(searchable_user.id)
      expect(results.to_a).to include(searchable_user)
    end

    it "does not return the user when it shouldn't" do
      results = User.search("penutbutter")
      expect(results.to_a).to_not include(searchable_user)
    end
  end

  describe "#assign_from_auth_hash", :vcr do
    it "updates the users attributes" do
      user.assign_from_auth_hash(github_omniauth_hash)
      expect(github_omniauth_hash.credentials.token).to eq(user.token)
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
      expect(user.flipper_id).to eq("User:#{user.id}")
    end
  end

  describe "#github_client" do
    it "sets or creates a new GitHubClient with the users token" do
      expect(user.github_client.class).to eql(Octokit::Client)
    end
  end

  describe "#github_user", :vcr do
    let(:user) { classroom_student }

    it "sets or creates a new GitHubUser with the users uid" do
      expect(user.github_user.class).to eql(GitHubUser)
      expect(user.github_user.id).to eql(user.uid)
    end
  end

  describe "#staff?" do
    it "returns if the User is a site_admin" do
      expect(user.staff?).to be(false)
      user.update(site_admin: true)
      expect(user.staff?).to be(true)
    end
  end

  describe "#github_client_scopes", :vcr do
    it "returns an Array of scopes" do
      user.assign_from_auth_hash(github_omniauth_hash)
      scopes = user.github_client_scopes

      %w[write:org read:org admin:org_hook delete_repo repo:status repo_deployment public_repo repo:invite user:email].each do |s| # rubocop:disable Metrics/LineLength
        expect(scopes).to include(s)
      end
    end
  end

  describe "#api_token", :vcr do
    it "generates a valid api token" do
      token = subject.api_token

      data = MessageVerifier.decode(token)
      expect(data).to_not be_nil
    end

    it "generates an api token with correct user id" do
      token = subject.api_token

      data = MessageVerifier.decode(token)
      expect(data[:user_id]).to eql(subject.id)
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

  describe "invite_statuses" do
    let(:invitation) { create(:assignment_invitation) }

    it "returns a list of invite statuses" do
      invite_status = create(:invite_status, user_id: user.id)
      expect(user.invite_statuses).to eq([invite_status])
    end

    it "on #destroy destroys invite status and not invitation" do
      invite_status = create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      user.destroy
      expect { invite_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(invitation.reload.nil?).to be_falsey
    end
  end

  describe "assignment_invitations" do
    let(:invitation) { create(:assignment_invitation) }

    it "returns a list of invitations through invite_statuses" do
      create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      expect(user.assignment_invitations).to eq([invitation])
    end
  end
end
