# frozen_string_literal: true

require "rails_helper"

RSpec.describe LtiConfiguration::GenericSettings do
  let(:settings) { described_class.new }

  it "platform_name should return nil" do
    expect(settings.platform_name).to be_nil
  end
end
