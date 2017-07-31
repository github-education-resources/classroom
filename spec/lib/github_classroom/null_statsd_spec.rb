# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::NullStatsD do
  subject { described_class.new }

  it "responds to #increment nil" do
    expect(subject).to respond_to(:increment)
    expect(subject.increment("foo", bad: "option")).to be_nil
  end

  it "responds to #timing with nil" do
    expect(subject).to respond_to(:timing)
    expect(subject.timing("foo", 25, bad: "option")).to be_nil
  end
end
