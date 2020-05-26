# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyResourceJob, type: :job do
  let(:organization) { classroom_org }

  it "uses the :default queue" do
    ActiveJob::Base.queue_adapter = :test
    expect do
      DestroyResourceJob.perform_later(organization)
    end.to have_enqueued_job.on_queue("default")
  end

  it "destroys the resource", :vcr do
    DestroyResourceJob.perform_now(organization)

    expect(Organization.exists?(organization.id)).to eq(false)
  end
end
