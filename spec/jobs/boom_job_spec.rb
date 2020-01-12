# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoomJob, type: :job do
  it "uses the :critical queue" do
    ActiveJob::Base.queue_adapter = :test
    expect do
      BoomJob.perform_later
    end.to have_enqueued_job.on_queue("critical")
  end

  it "raises BOOM" do
    expect { BoomJob.perform_now }.to raise_error(StandardError, "BOOM")
  end
end
