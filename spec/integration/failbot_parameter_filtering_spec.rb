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

  it "filters out sensitive data attributes before reporting to the backend" do
    # Simulate when params are automatically pushed into failbot context
    Failbot.push(params: {
      my_model_name: {
        super_secret_param: "sally@mit.edu",
        repository_id: 123,
      }
    })

    Failbot.report(Exception.new)
    report = Failbot.reports.last

    # super_secret_param is not in ParameterFiltering::ALLOWLISTED_PARAMETERS
    expect(report.inspect).not_to include("sally@mit.edu")

    # repository_id is in ParameterFiltering::ALLOWLISTED_PARAMETERS
    expect(report.inspect).to include("123")
  end
end
