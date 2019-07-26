# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyResourceJob, type: :job do
  let(:organization) { classroom_org }

  it "destroys the resource", :vcr do
    expect do
      DestroyResourceJob.perform_now(organization)
    end.to change { Organization.exists?(classroom_org.id) }
  end
end
