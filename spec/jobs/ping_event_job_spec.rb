# frozen_string_literal: true

require "rails_helper"

RSpec.describe PingEventJob, type: :job do
  let(:payload) { json_payload("webhook_events/ping.json") }

  it "updates the organization to show the webhook is active" do
    organization = create(:organization, github_id: payload["organization"]["id"], webhook_id: payload["hook_id"])
    expect(organization.is_webhook_active?).to be_falsey

    PingEventJob.perform_now(payload)

    expect(organization.reload.is_webhook_active?).to be_truthy
  end
end
