# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::NullStatsD do
  subject { described_class.new }

  it "responds to #increment nil" do
    assert subject.respond_to?("increment")
    assert_predicate subject.increment("foo", bad: "option"), :nil?
  end

  it "responds to #time with nil" do
    assert subject.respond_to?("time")
    assert_predicate subject.time("foo", bad: "option"), :nil?
  end
end
