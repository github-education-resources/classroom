# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyResourceJob, type: :job do
  it "destroys the resource", :vcr do
    organization = classroom_org

    DestroyResourceJob.perform_now(organization)

    expect(Organization.exists?(organization.id)).to eq(false)
  end
end
