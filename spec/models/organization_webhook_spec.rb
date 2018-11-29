# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationWebhook, type: :model do
  let(:organization) { classroom_org }
  let(:client) { classroom_teacher.github_client }
  subject do
    organization_webhook = create(:organization_webhook, github_organization_id: organization.github_id)
    organization_webhook.organizations << organization
    organization_webhook
  end

  it { should have_many(:organizations) }
  it { should have_many(:users).through(:organizations) }

  it { should validate_uniqueness_of(:github_id).allow_nil }

  it { should validate_presence_of(:github_organization_id) }
  it { should validate_uniqueness_of(:github_organization_id) }

  describe "#admin_org_hook_scoped_github_client" do
    context "token is present" do
      before do
        allow(subject).to receive_message_chain(:users, :first, :token) { "token" }
      end

      it "returns a Octokit::Client" do
        expect(subject.admin_org_hook_scoped_github_client).to be_a(Octokit::Client)
      end
    end

    context "token is nil" do
      before do
        allow(subject).to receive_message_chain(:users, :first) { nil }
      end

      it "raises a NoValidTokenError" do
        expect { subject.admin_org_hook_scoped_github_client }.to raise_error(described_class::NoValidTokenError)
      end
    end
  end

  describe "#create_org_hook!", :vcr do
    context "GitHub::Error is raised" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:create_organization_webhook)
          .and_raise(GitHub::Error)
      end

      it "raises a GitHub::Error" do
        expect { subject.create_org_hook!(client: client) }
          .to raise_error(GitHub::Error)
      end
    end

    context "ActiveRecord::RecordInvalid is raised" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive_message_chain(:create_organization_webhook, :id) { 0 }
        expect(subject)
          .to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises a ActiveRecord::RecordInvalid" do
        expect { subject.create_org_hook!(client: client) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "org hook is successfully created" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive_message_chain(:create_organization_webhook, :id) { 0 }
      end

      it "returns true" do
        expect(subject.create_org_hook!(client: client)).to be_truthy
      end
    end
  end

  describe "#users_with_admin_org_hook_scope" do
    context "user with admin_org hook scope doesn't exist" do
      before do
        User.any_instance.stub(:github_client_scopes)
          .and_return([])
      end

      it "returns an empty list" do
        expect(subject.send(:users_with_admin_org_hook_scope)).to be_empty
      end
    end

    context "user with admin_org hook scope exists" do
      before do
        User.any_instance.stub(:github_client_scopes)
          .and_return(["admin:org_hook"])
      end

      it "returns a list with the user" do
        expect(subject.send(:users_with_admin_org_hook_scope)).to_not be_empty
      end
    end
  end

  describe "#webhook_url" do
    context "webhook_url_prefix is present" do
      it "returns a valid webhook_url" do
        expect(subject.send(:webhook_url)).to be_truthy
      end
    end

    context "webhook_url_prefix is blank" do
      before do
        stub_const("ENV", {})
      end

      it "returns a valid webhook_url" do
        expect { subject.send(:webhook_url) }
          .to raise_error(RuntimeError, "CLASSROOM_WEBHOOK_URL_PREFIX is not set, please check your .env file")
      end
    end
  end
end
