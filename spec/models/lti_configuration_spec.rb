# frozen_string_literal: true

require "rails_helper"

RSpec.describe LtiConfiguration, type: :model do
  let(:organization) { classroom_org }
  let(:lti_configuration) { create(:lti_configuration, organization: organization) }

  describe "lms_name" do
    it "returns the name corresponding an existing enum" do
      lti_configuration.lms_type = :canvas
      expect(lti_configuration.lms_name).to eq("Canvas")
    end

    it "returns the default name when unspecified type is :other" do
      lti_configuration.lms_type = :other
      expect(lti_configuration.lms_name).to eq("Other learning management system")
    end

    it "returns a custom default name when specified type is :other" do
      custom_name = Faker::Company.name
      lti_configuration.lms_type = :other
      expect(lti_configuration.lms_name(default_name: custom_name)).to eq(custom_name)
    end
  end

  describe "relationships" do
    it { should belong_to(:organization) }
  end

  describe "cached_launch_message_nonce=" do
    before(:each) do
      GitHubClassroom::LTI::MessageStore.any_instance.stub(:delete_message).and_return(nil)
    end

    it "removes the old corresponding message from LTI::MessageStore on set" do
      expect_any_instance_of(GitHubClassroom::LTI::MessageStore)
        .to receive(:delete_message)
        .with(lti_configuration.cached_launch_message_nonce)

      lti_configuration.cached_launch_message_nonce = Faker::Code.isbn
    end
  end

  describe "launch_message" do
    context "with cached_launch_message_nonce" do
      it "fetches the corresponding message from LTI::MessageStore" do
        expect_any_instance_of(GitHubClassroom::LTI::MessageStore)
          .to receive(:get_message)
          .with(lti_configuration.cached_launch_message_nonce)

        lti_configuration.launch_message
      end
    end

    context "without cached_launch_message_nonce" do
      before(:each) do
        lti_configuration.cached_launch_message_nonce = nil
        lti_configuration.save!
      end

      it "returns nil before calling out to LTI::MessageStore" do
        expect(GitHubClassroom.lti_message_store(lti_configuration: lti_configuration))
          .not_to receive(:get_message)
          .with(lti_configuration.cached_launch_message_nonce)

        expect(lti_configuration.launch_message).to be_nil
      end
    end
  end
end
