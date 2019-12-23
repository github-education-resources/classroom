# frozen_string_literal: true

require "rails_helper"

RSpec.describe "failbot context filtering" do
  before do
    # Tell failbot to report errors instead of raising for these tests
    @raise_errors = Failbot.instance_variable_get("@raise_errors")
    Failbot.instance_variable_set("@raise_errors", false)

    Failbot.reports.clear
  end

  after do
    # Reset failbot settings
    Failbot.instance_variable_set("@raise_errors", @raise_errors)
  end

  it "filters out URL paths and params in error messages before reporting to the backend" do
    Failbot.report(Exception.new("https://example.com/super/sensitive/url?thisis=secret"))

    report = Failbot.reports.last

    expect(report.inspect).not_to include("super")
    expect(report.inspect).not_to include("sensitive")
    expect(report.inspect).not_to include("url")
    expect(report.inspect).not_to include("thisis")
    expect(report.inspect).not_to include("secret")

    expect(report.inspect).to include("https://example.com/[PATH_FILTERED]")
  end
end
