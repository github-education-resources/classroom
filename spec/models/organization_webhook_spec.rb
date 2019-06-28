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

  describe "#ensure_webhook_is_active!", :vcr do
    context "client is nil" do
      before do
        expect(subject)
          .to receive(:admin_org_hook_scoped_github_client)
          .and_return(client)
      end

      context "github_id is not present" do
        context "there isn't an org hook on github" do
          before do
            expect(subject).to receive(:github_id).and_return(nil).twice
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(nil)
          end

          it "invokes create_org_hook!" do
            expect(subject).to receive(:create_org_hook!).and_return(true)
            subject.ensure_webhook_is_active!
          end

          it "returns true" do
            expect(subject).to receive(:create_org_hook!).and_return(true)
            expect(subject.ensure_webhook_is_active!).to be_truthy
          end
        end

        context "hook exists on github" do
          before do
            expect(subject).to receive(:github_id).and_return(nil, true)
            expect(subject).to receive_message_chain(:github_org_hook, :active?) { true }
          end

          it "invokes retrieve_org_hook_id!" do
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(true)
            subject.ensure_webhook_is_active!
          end

          it "returns true" do
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(true)
            expect(subject.ensure_webhook_is_active!).to be_truthy
          end
        end
      end

      context "github_org_hook is not found" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { nil }
        end

        it "invokes create_org_hook!" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          subject.ensure_webhook_is_active!
        end

        it "returns true" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          expect(subject.ensure_webhook_is_active!).to be_truthy
        end
      end

      context "github_org_hook was NotFound" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { nil }
        end

        it "invokes create_org_hook!" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          subject.ensure_webhook_is_active!
        end

        it "returns true" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          expect(subject.ensure_webhook_is_active!).to be_truthy
        end
      end

      context "github_org_hook is not active" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { false }
        end

        it "invokes activate_org_hook!" do
          expect(subject).to receive(:activate_org_hook).and_return(true)
          subject.ensure_webhook_is_active!
        end

        it "returns true" do
          expect(subject).to receive(:activate_org_hook).and_return(true)
          expect(subject.ensure_webhook_is_active!).to be_truthy
        end
      end

      context "github_org_hook is active" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { true }
        end

        it "does not invoke create_org_hook!" do
          expect(subject).to_not receive(:create_org_hook!)
          subject.ensure_webhook_is_active!
        end

        it "returns true" do
          expect(subject.ensure_webhook_is_active!).to be_truthy
        end
      end
    end

    context "client is present" do
      context "github_id is not present" do
        context "there isn't an org hook on github" do
          before do
            expect(subject).to receive(:github_id).and_return(nil).twice
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(nil)
          end

          it "invokes create_org_hook!" do
            expect(subject).to receive(:create_org_hook!).and_return(true)
            subject.ensure_webhook_is_active!(client: client)
          end

          it "returns true" do
            expect(subject).to receive(:create_org_hook!).and_return(true)
            expect(subject.ensure_webhook_is_active!(client: client)).to be_truthy
          end
        end

        context "hook exists on github" do
          before do
            expect(subject).to receive(:github_id).and_return(nil, true)
            expect(subject).to receive_message_chain(:github_org_hook, :active?) { true }
          end

          it "invokes retrieve_org_hook_id!" do
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(0)
            subject.ensure_webhook_is_active!(client: client)
          end

          it "returns true" do
            expect(subject).to receive(:retrieve_org_hook_id!).and_return(0)
            expect(subject.ensure_webhook_is_active!(client: client)).to be_truthy
          end
        end
      end

      context "github_org_hook was NotFound" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { nil }
        end

        it "invokes create_org_hook!" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          subject.ensure_webhook_is_active!(client: client)
        end

        it "returns true" do
          expect(subject).to receive(:create_org_hook!).and_return(true)
          expect(subject.ensure_webhook_is_active!(client: client)).to be_truthy
        end
      end

      context "github_org_hook is not active" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { false }
        end

        it "invokes activate_org_hook!" do
          expect(subject).to receive(:activate_org_hook).and_return(true)
          subject.ensure_webhook_is_active!(client: client)
        end

        it "returns true" do
          expect(subject).to receive(:activate_org_hook).and_return(true)
          expect(subject.ensure_webhook_is_active!(client: client)).to be_truthy
        end
      end

      context "github_org_hook is active" do
        before do
          expect(subject).to receive(:github_id).and_return(true).twice
          expect(subject).to receive_message_chain(:github_org_hook, :active?) { true }
        end

        it "does not invoke create_org_hook!" do
          expect(subject).to_not receive(:create_org_hook!)
          subject.ensure_webhook_is_active!(client: client)
        end

        it "returns true" do
          expect(subject.ensure_webhook_is_active!(client: client)).to be_truthy
        end
      end
    end
  end

  describe "#retrieve_org_hook_id!", :vcr do
    context "org hook exists" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:organization_webhooks)
          .and_return([double("Classroom webhook", id: 0)])
      end

      context "saves successfully" do
        it "returns the expected id" do
          expect(subject.send(:retrieve_org_hook_id!, client)).to eq(0)
        end

        it "saves the new id" do
          subject.send(:retrieve_org_hook_id!, client)
          expect(subject.reload.github_id).to eq(0)
        end
      end

      context "raises a ActiveRecord::RecordInvalid" do
        before do
          expect(subject).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "returns nil" do
          expect(subject.send(:retrieve_org_hook_id!, client)).to be_nil
        end
      end
    end

    context "org hook does not exist" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:organization_webhooks)
          .and_return([])
      end

      it "retruns nil" do
        expect(subject.send(:retrieve_org_hook_id!, client)).to be_nil
      end
    end

    context "raises a GitHub::Error" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:organization_webhooks)
          .and_raise(GitHub::Error)
      end

      it "returns nil" do
        expect(subject.send(:retrieve_org_hook_id!, client)).to be_nil
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
        expect { subject.create_org_hook!(client) }
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
        expect_any_instance_of(GitHubOrganization)
          .to receive(:remove_organization_webhook).and_return(true)
      end

      it "raises a ActiveRecord::RecordInvalid" do
        expect { subject.create_org_hook!(client) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "org hook is successfully created" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive_message_chain(:create_organization_webhook, :id) { 0 }
      end

      it "returns true" do
        expect(subject.create_org_hook!(client)).to be_truthy
      end

      it "saves the new id" do
        subject.create_org_hook!(client)
        expect(subject.github_id).to eq(0)
      end
    end
  end

  describe "#activate_org_hook!", :vcr do
    context "GitHub::Error is raised" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:activate_organization_webhook)
          .and_raise(GitHub::Error)
      end

      it "raises a GitHub::Error" do
        expect { subject.activate_org_hook(client) }
          .to raise_error(GitHub::Error)
      end
    end

    context "org hook is successfully activated" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive_message_chain(:activate_organization_webhook) { 0 }
      end

      it "returns true" do
        expect(subject.activate_org_hook(client)).to be_truthy
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
          .to raise_error(RuntimeError, described_class::WEBHOOK_URL_DEVELOPMENT_ERROR)
      end
    end
  end
end
