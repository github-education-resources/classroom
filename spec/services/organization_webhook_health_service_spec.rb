# frozen_string_literal: true

require "rails_helper"

describe OrganizationWebhookHealthService do
  let(:organization_webhooks) do
    organization_webhooks = []
    3.times do |id|
      organization_webhooks << create(:organization_webhook, github_organization_id: id)
    end
    3.times do |id|
      organization_webhooks << create(:organization_webhook, github_organization_id: id + 3, github_id: id)
    end
    organization_webhooks
  end

  describe "class#perform" do
    it "invokes #perform" do
      expect_any_instance_of(described_class).to receive(:perform)
      described_class.perform
    end
  end

  describe "class#perform_and_print" do
    it "invokes class#perform and class#print_results" do
      expect(described_class).to receive(:perform)
      expect(described_class).to receive(:print_results)
      described_class.perform_and_print
    end
  end

  describe "#perform" do
    context "all_organizations: false" do
      subject { described_class.new }

      before do
        organization_webhooks
      end

      it "invokes OrganizationWebhook.where(github_id: nil)" do
        expect(OrganizationWebhook)
          .to receive(:where).with(github_id: nil).twice.and_return(OrganizationWebhook.where(github_id: nil))
        subject.perform
      end

      context "ensure_organization_webhook_exists! succeeds" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(
              described_class::Result.success,
              described_class::Result.success,
              described_class::Result.success
            )
        end

        it "success field is all org webhooks without github_id" do
          organization_webhooks_without_github_ids = organization_webhooks
            .select { |org_hook| org_hook.github_id.blank? }
            .map(&:id)
          expect(subject.perform[:success])
            .to eq(organization_webhooks_without_github_ids)
        end
      end

      context "ensure_organization_webhook_exists! fails" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new)
            )
        end

        it "failed field is all org webhooks withought github_id" do
          organization_webhooks_without_github_ids = organization_webhooks
            .select { |org_hook| org_hook.github_id.blank? }
            .map(&:id)
          expect(subject.perform[:failed]["GitHub::Error"])
            .to eq(organization_webhooks_without_github_ids)
        end
      end
    end

    context "all_organizations: true" do
      subject { described_class.new(all_organizations: true) }

      before do
        organization_webhooks
      end

      it "OrganizationWebhook does not receive :where" do
        expect(OrganizationWebhook)
          .to_not receive(:where)
        subject.perform
      end

      context "ensure_organization_webhook_exists! succeeds" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(
              described_class::Result.success,
              described_class::Result.success,
              described_class::Result.success,
              described_class::Result.success,
              described_class::Result.success,
              described_class::Result.success
            )
        end

        it "success field is all org webhooks" do
          organization_webhook_ids = organization_webhooks.map(&:id)
          expect(subject.perform[:success])
            .to eq(organization_webhook_ids)
        end
      end

      context "ensure_organization_webhook_exists! fails" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new),
              described_class::Result.failed(GitHub::Error.new)
            )
        end

        it "failed field is all org webhooks" do
          organization_webhook_ids = organization_webhooks.map(&:id)
          expect(subject.perform[:failed]["GitHub::Error"])
            .to eq(organization_webhook_ids)
        end
      end
    end
  end

  describe "#ensure_organization_webhook_exists!" do
    subject { described_class.new }
    let(:organization_webhook) { create(:organization_webhook) }

    context "#ensure_webhook_is_active! returns true" do
      before do
        expect(organization_webhook)
          .to receive(:ensure_webhook_is_active!)
          .and_return(true)
      end

      it "is a success" do
        expect(subject.send(:ensure_organization_webhook_exists!, organization_webhook).success?)
          .to be_truthy
      end
    end

    context "#ensure_webhook_is_active! raises a ActiveRecord::RecordInvalid" do
      before do
        expect(organization_webhook)
          .to receive(:ensure_webhook_is_active!)
          .and_raise(ActiveRecord::RecordInvalid)
      end

      it "failed" do
        expect(subject.send(:ensure_organization_webhook_exists!, organization_webhook).failed?)
          .to be_truthy
      end
    end

    context "#ensure_webhook_is_active! raises a GitHub::Error" do
      before do
        expect(organization_webhook)
          .to receive(:ensure_webhook_is_active!)
          .and_raise(GitHub::Error)
      end

      it "failed" do
        expect(subject.send(:ensure_organization_webhook_exists!, organization_webhook).failed?)
          .to be_truthy
      end
    end

    context "#ensure_webhook_is_active! raises a OrganizationWebhook::NoValidTokenError" do
      before do
        expect(organization_webhook)
          .to receive(:ensure_webhook_is_active!)
          .and_raise(OrganizationWebhook::NoValidTokenError)
      end

      it "failed" do
        expect(subject.send(:ensure_organization_webhook_exists!, organization_webhook).failed?)
          .to be_truthy
      end
    end
  end
end
