# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { create(:user) }

  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }

  describe "#assign_from_auth_hash" do
    it "updates the users attributes" do
      stub_access_token_comparison(
        old_token:  subject.token,
        new_token:  github_omniauth_hash.credentials.token,
        new_scopes: ["repo"]
      )

      subject.assign_from_auth_hash(github_omniauth_hash)
      expect(subject.token).to eq(github_omniauth_hash.credentials.token)
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

  describe "#github_user" do
    it "sets or creates a new GitHubUser with the users uid" do
      stub_get_a_single_user(subject.uid)

      expect(subject.github_user.class).to eql(GitHubUser)
      expect(subject.github_user.id).to eql(subject.uid)
    end
  end

  describe "#staff?" do
    it "returns if the User is a site_admin" do
      expect(subject.staff?).to be_falsey
      subject.update(site_admin: true)
      expect(subject.staff?).to be_truthy
    end
  end

  describe "#github_client_scopes" do
    it "returns an Array of scopes" do
      stub_check_application_authorization(subject.token)
      stub_user(subject.uid)

      scopes = subject.github_client_scopes

      expect(scopes).to be_a(Array)
    end
  end

  describe "#api_token" do
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

  describe "tokens" do
    it "does not allow a User to lose their token scope" do
      good_token = subject.token
      bad_token  = "e72e16c7e42f292c6912e7710c838347ae178b4a"

      stub_access_token_comparison(
        old_token: subject.token,
        old_scopes: GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT,
        new_token: bad_token,
        new_scopes: GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
      )

      subject.update_attributes(token: bad_token)
      expect(subject.token).to eql(good_token)
    end

    it "updates the token if there if then new one has more scopes" do
      student = build(:user)
      stub_check_application_authorization(student.token, scopes: GitHubClassroom::Scopes::ASSIGNMENT_STUDENT)

      student.save

      new_token = "e72e16c7e42f292c6912e7710c838347ae178b4a"
      stub_check_application_authorization(new_token, scopes: GitHubClassroom::Scopes::GROUP_ASSIGNMENT_STUDENT)

      student.update_attributes(token: new_token)

      expect(student.token).to eql(new_token)
    end
  end

  describe "invite_statuses" do
    let(:invitation) { create(:assignment_invitation) }

    it "returns a list of invite statuses" do
      invite_status = create(:invite_status, user: subject)
      expect(subject.invite_statuses).to eq([invite_status])
    end

    it "on #destroy destroys invite status and not invitation" do
      invite_status = create(:invite_status, user: subject, assignment_invitation: invitation)
      subject.destroy

      expect { invite_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(invitation.reload.nil?).to be_falsey
    end
  end

  describe "assignment_invitations" do
    let(:invitation) { create(:assignment_invitation) }

    it "returns a list of invitations through invite_statuses" do
      create(:invite_status, user: subject, assignment_invitation: invitation)
      expect(subject.assignment_invitations).to eq([invitation])
    end
  end
end
