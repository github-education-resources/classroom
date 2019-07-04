# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LtiMessageStore do
  subject { described_class }
  let(:consumer_key)  { "consumer_key" }
  let(:shared_secret) { "shared_secret" }
  let(:redis_store)   { Redis.new }
  let(:lti_launch_params) do
    {
      "oauth_consumer_key": "mock_consumer_key",
      "oauth_signature_method": "HMAC-SHA1",
      "oauth_timestamp": DateTime.now.to_i.to_s,
      "oauth_nonce": "mock_nonce",
      "oauth_version": "1.0",
      "context_id": "mock_context_id",
      "context_label": "CONTEXT-LABEL",
      "context_title": "Context/Course Title",
      "ext_roles": "urn:lti:instrole:ims/lis/Instructor,urn:lti:role:ims/lis/Instructor,urn:lti:sysrole:ims/lis/User",
      "lis_person_contact_email_primary": "test@email.com",
      "lis_person_name_full": "Test User",
      "lti_message_type": "basic-lti-launch-request",
      "lti_version": "LTI-1p0",
      "user_id": "mock_user_id",
      "oauth_signature": "mock_oauth_signature"
    }
  end

  let(:lti_message) { subject.construct_message(lti_launch_params) }

  before(:each) do
    redis_store.flushdb
  end

  after(:each) do
    redis_store.quit
  end

  it "can serialize params to an IMS::LTI::Models::Messages::Message" do
    expect(lti_message).to be_a_kind_of(IMS::LTI::Models::Messages::Message)
  end

  context "without necessary initializtion params" do
    it "should error when consumer_key is not present" do
      expect { subject.new(shared_secret: shared_secret, redis_store: redis_store) }
        .to raise_error(ArgumentError)
    end

    it "should error when shared_secret is not present" do
      expect { subject.new(consumer_key: consumer_key, redis_store: redis_store) }
        .to raise_error(ArgumentError)
    end

    it "should error when redis_store is not present" do
      expect { subject.new(consumer_key: consumer_key, shared_secret: shared_secret) }
        .to raise_error(ArgumentError)
    end
  end

  context "with necessary initialization params" do
    let(:instance) { subject.new(consumer_key: consumer_key, shared_secret: shared_secret, redis_store: redis_store) }

    it "should initialize" do
      expect(instance).to be_an_instance_of(subject)
    end

    context "saving messages" do
      it "returns nonce after saving message" do
        expected_nonce = lti_message.oauth_nonce
        actual_nonce = instance.save_message(lti_message)

        expect(actual_nonce).to eq(expected_nonce)
      end

      it "returns false if unable to save" do
        Redis.any_instance.stub(:set).and_return(false)
        result = instance.save_message(lti_message)

        expect(result).to eq(false)
      end
    end

    context "retrieving messages" do
      it "returns a message for existing nonce" do
        nonce = instance.save_message(lti_message)
        actual_message = instance.get_message(nonce)

        expect(actual_message).to be_a_kind_of(IMS::LTI::Models::Messages::Message)
        expect(actual_message.oauth_nonce).to eq(lti_message.oauth_nonce)
      end

      it "returns nil for nonexistant nonce" do
        actual_message = instance.get_message(lti_message.oauth_nonce)
        expect(actual_message).to be_nil
      end
    end

    context "launch_valid?" do
      it "returns true when launch is valid" do
        expect(instance.message_valid?(lti_message)).to be true
      end

      it "returns false when nonce is a duplicate" do
        instance.save_message(lti_message)
        expect(instance.message_valid?(lti_message)).to be false
      end

      it "returns false when nonce is too old" do
        old_lti_launch_params = lti_launch_params.clone
        old_lti_launch_params["oauth_timestamp"] = 5.minutes.ago.to_i.to_s
        old_lti_message = subject.construct_message(old_lti_launch_params)

        expect(instance.message_valid?(old_lti_message)).to be false
      end
    end
  end
end
