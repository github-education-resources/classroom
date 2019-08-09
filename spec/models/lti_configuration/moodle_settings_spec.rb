# frozen_string_literal: true

require "rails_helper"

RSpec.describe LtiConfiguration::MoodleSettings do
  let(:launch_message) { IMS::LTI::Models::Messages::BasicLTILaunchRequest.new }
  let(:settings) { described_class.new(launch_message) }
  let(:general)  { LtiConfiguration::GenericSettings.new(launch_message) }

  it "platform_name should be 'Moodle'" do
    expect(settings.platform_name).to eql("Moodle")
  end

  it "lti_version should be inherited" do
    expect(settings.lti_version).to eql(general.lti_version)
  end
end
