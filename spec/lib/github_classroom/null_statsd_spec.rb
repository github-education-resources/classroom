# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::NullStatsD do
  subject { described_class.new }

  it "responds to #increment nil" do
    expect(subject).to respond_to(:increment)
    expect(subject.increment("foo", bad: "option")).to be_nil
  end

  it "responds to #time with nil" do
    expect(subject).to respond_to(:time)
    expect(subject.time("foo", bad: "option")).to be_nil
  end
end
