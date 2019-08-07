# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::Mixins::RequestSigning do
  let(:consumer_key) { SecureRandom.uuid }
  let(:secret) { SecureRandom.uuid }
  let(:klass) { Class.new { include GitHubClassroom::LTI::Mixins::RequestSigning } }
  let(:instance) { klass.new }

  before(:each) do
    instance.instance_variable_set(:@consumer_key, consumer_key)
    instance.instance_variable_set(:@secret, secret)
  end

  context "lti_request" do
    let(:endpoint) { "http://www.example.com" }

    it "produces a valid LTI 1.1 signature" do
      req = instance.lti_request(endpoint, lti_version: 1.1)
      params = Rack::Utils.parse_nested_query(req["Authorization"])

      validator = IMS::LTI::Services::MessageAuthenticator.new(endpoint, params, secret)
      expect(validator.valid_signature?)
    end

    it "produces a valid LTI 1.0 signature" do
      req = instance.lti_request(endpoint, lti_version: 1.0)
      params = Rack::Utils.parse_nested_query(req.body)

      validator = IMS::LTI::Services::MessageAuthenticator.new(endpoint, params, secret)
      expect(validator.valid_signature?)
    end
  end
end
