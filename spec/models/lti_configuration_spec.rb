# frozen_string_literal: true

require "rails_helper"

RSpec.describe LtiConfiguration, type: :model do
  let(:organization) { classroom_org }
  let(:lti_configuration) { create(:lti_configuration, organization: organization) }

  describe "relationships" do
    it { should belong_to(:organization) }
  end

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
        end

        after(:each) do
          redis_store.quit
        end

        it "returns the url corresponding to the nonce" do
          expect(lti_configuration.context_membership_url(nonce: nonce)).to eq(uncached_membership_url)
        end

        it "persists the url to the model" do
          expect(lti_configuration.context_membership_url).to be_nil
          lti_configuration.context_membership_url(nonce: nonce)
          lti_configuration.reload
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
