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
      expect(lti_configuration.lms_name).to eq("Other Learning Management System")
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

  # TODO: literally all of this can be removed (after a little more untangling)
  describe "context_membership_url" do
    context "with cached value" do
      let(:cached_url) { "www.example.com" }
      before(:each) do
        lti_configuration.context_membership_url = cached_url
      end

      it "should return the cached value when use_cache: true" do
        expect(lti_configuration.context_membership_url).to eq(cached_url)
      end

      it "should not return the cached value when use_cache: false" do
        expect(lti_configuration.context_membership_url(use_cache: false)).to be_nil
      end
    end

    context "without cached value" do
      context "with no nonce" do
        before(:each) do
          lti_configuration.cached_launch_message_nonce = nil
          lti_configuration.save!
        end

        it "returns nil" do
          expect(lti_configuration.context_membership_url).to be_nil
        end

        it "returns the same value regardless of what use_cache is" do
          with_cache = lti_configuration.context_membership_url
          without_cache = lti_configuration.context_membership_url(use_cache: false)

          expect(with_cache).to eq(without_cache)
        end
      end

      context "with nonce" do
        let(:nonce) { Faker::Code.isbn }
        let(:redis_store) { Redis.new }
        let(:uncached_membership_url) { "membership.lms.edu" }
        let(:lti_launch_message) do
          GitHubClassroom::LTI::MessageStore.construct_message(
            custom_context_memberships_url: uncached_membership_url,
            oauth_nonce: nonce
          )
        end

        before(:each) do
          redis_store.flushdb

          GitHubClassroom.stub(:redis).and_return(redis_store)
          GitHubClassroom
            .lti_message_store(consumer_key: lti_configuration.consumer_key)
            .save_message(lti_launch_message)

          lti_configuration.cached_launch_message_nonce = nonce
          lti_configuration.save!
        end

        after(:each) do
          redis_store.quit
        end

        it "returns the url corresponding to the nonce" do
          expect(lti_configuration.context_membership_url).to eq(uncached_membership_url)
        end

        it "returns the same regardless of what use_cache is" do
          with_cache = lti_configuration.context_membership_url
          without_cache = lti_configuration.context_membership_url(use_cache: false)

          expect(with_cache).to eq(without_cache)
        end
      end
    end
  end
end
