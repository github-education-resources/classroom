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

  it { should validate_uniqueness_of(:github_id).allow_nil }

  it { should validate_presence_of(:github_organization_id) }
  it { should validate_uniqueness_of(:github_organization_id) }

  describe "#github_organization" do
    it "requests a GitHubOrganization" do
      expect_any_instance_of(Organization).to receive(:github_organization)
      subject.github_organization
    end

    context "has no organizations" do
      it "returns nil" do
        expect(subject)
          .to receive(:organizations)
          .and_return([])
        expect(subject.github_organization).to be_nil
      end
    end
  end
end
