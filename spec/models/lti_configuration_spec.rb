# frozen_string_literal: true

require "rails_helper"

RSpec.describe LtiConfiguration, type: :model do
  let(:organization) { classroom_org }
  let(:lti_configuration) { create(:lti_configuration, organization: organization) }
  it { should belong_to(:organization) }

  describe "lms_name" do
    it "returns the name corresponding an existing enum" do
      lti_configuration.lms_type = :canvas
      expect(lti_configuration.lms_name).to eq("Canvas")
    end

    it "returns the default name when unspecified type is :other" do
      lti_configuration.lms_type = :other
      expect(lti_configuration.lms_name).to eq("Other Learning Management System")
    end

    it "returns a custom default name when specified type is :other" do
      custom_name = Faker::Company.name
      lti_configuration.lms_type = :other
      expect(lti_configuration.lms_name(default_name: custom_name)).to eq(custom_name)
    end
  end
end
