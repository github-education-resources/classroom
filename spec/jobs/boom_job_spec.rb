# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoomJob, type: :job do
  it "raises BOOM" do
    expect { BoomJob.perform_now }.to raise_error(StandardError, "BOOM")
  end
end
