# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageVerifier do
  context "#api_secret" do
    context "secret present in env" do
      it "returns the api secret" do
        expect(MessageVerifier.send(:api_secret)).to eq(Rails.application.secrets.api_secret)
      end
    end

    context "secret missing in env" do
      before do
        Rails.application.secrets.stub(:api_secret) { nil }
        MessageVerifier.instance_variable_set(:@api_secret, nil)
      end

      it "raises error about env file" do
        error_message = "API_SECRET is not set, please check your .env file"
        expect { MessageVerifier.send(:api_secret) }.to raise_error.with_message(error_message)
      end
    end
  end

  context "#encode" do
    before do
      Timecop.freeze
    end

    it "generates valid token with payload" do
      token = MessageVerifier.encode(test: "success")

      data = MessageVerifier.decode(token)
      expect(data[:test]).to eql("success")
    end

    it "generates valid token which expires in 5 minutes" do
      token = MessageVerifier.encode(test: "success")

      data = MessageVerifier.decode(token)
      expect(data[:exp]).to eql(5.minutes.from_now)
    end

    it "generates valid token with passed in expiration" do
      token = MessageVerifier.encode({ test: "success" }, 1.minute.from_now)

      data = MessageVerifier.decode(token)
      expect(data[:exp]).to eql(1.minute.from_now)
    end

    after do
      Timecop.return
    end
  end

  context "#decode" do
    before do
      Timecop.freeze
    end

    it "extracts parameters from valid token" do
      token = MessageVerifier.encode(a: 1, b: 2, c: 3)

      data = MessageVerifier.decode(token)
      expect(data[:a]).to eql(1)
      expect(data[:b]).to eql(2)
      expect(data[:c]).to eql(3)
    end

    it "returns nil for expired token" do
      token = MessageVerifier.encode({ test: "success" }, 30.seconds.ago)

      data = MessageVerifier.decode(token)
      expect(data).to be_nil
    end

    it "returns nil for malformed token" do
      token = "malformed token"

      data = MessageVerifier.decode(token)
      expect(data).to be_nil
    end

    after do
      Timecop.return
    end
  end
end
