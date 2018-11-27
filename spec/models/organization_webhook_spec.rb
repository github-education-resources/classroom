# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationWebhook, type: :model do
  let(:organization) { classroom_org }
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

      it "raises a NoValidTokenError" do
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
end
