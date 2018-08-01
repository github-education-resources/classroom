# frozen_string_literal: true

require "rails_helper"

RSpec.describe JsonWebToken do
  context "#jwt_secret" do
    context "secret present in env" do
      it "returns the jwt secret" do
        expect(JsonWebToken.send(:jwt_secret)).to eq(Rails.application.secrets.jwt_secret)
      end
    end

    context "secret missing in env" do
      before do
        Rails.application.secrets.stub(:jwt_secret) { nil }
        JsonWebToken.instance_variable_set(:@jwt_secret, nil)
      end

      it "raises error about env file" do
        error_message = "JWT_SECRET is not set, please check you .env file"
        expect { JsonWebToken.send(:jwt_secret) }.to raise_error.with_message(error_message)
      end
    end
  end

  context "#encode" do
    before do
      Timecop.freeze
    end

    it "generates valid token with payload" do
      token = JsonWebToken.encode(test: "success")

      data = JsonWebToken.decode(token)
      expect(data["test"]).to eql("success")
    end

    it "generates valid token which expires in 5 minutes" do
      token = JsonWebToken.encode(test: "success")

      data = JsonWebToken.decode(token)
      expect(data["exp"]).to eql(5.minutes.from_now.to_i)
    end

    it "generates valid token with passed in expiration" do
      token = JsonWebToken.encode({ test: "success" }, 1.minute.from_now)

      data = JsonWebToken.decode(token)
      expect(data["exp"]).to eql(1.minute.from_now.to_i)
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
      token = JsonWebToken.encode(a: 1, b: 2, c: 3)

      data = JsonWebToken.decode(token)
      expect(data["a"]).to eql(1)
      expect(data["b"]).to eql(2)
      expect(data["c"]).to eql(3)
    end

    it "returns nil for expired token" do
      token = JsonWebToken.encode({ test: "success" }, 30.seconds.ago)

      data = JsonWebToken.decode(token)
      expect(data).to be_nil
    end

    it "returns nil for malformed token" do
      token = "malformed token"

      data = JsonWebToken.decode(token)
      expect(data).to be_nil
    end

    after do
      Timecop.return
    end
  end
end
