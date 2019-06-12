# frozen_string_literal: true

require "base64"

class MessageVerifier
  class TokenExpired < StandardError; end
  class << self
    def encode(payload, exp = 5.minutes.from_now)
      payload[:exp] ||= exp
      Base64.urlsafe_encode64(verifier.generate(payload))
    end

    def decode(token)
      body = verifier.verify(Base64.urlsafe_decode64(token))

      raise MessageVerifier::TokenExpired if Time.current > body[:exp]
      body
    rescue ActiveSupport::MessageVerifier::InvalidSignature,
           ArgumentError,
           MessageVerifier::TokenExpired
      nil
    end

    private

    def verifier
      @verifier = ActiveSupport::MessageVerifier.new(api_secret, digest: "SHA256")
    end

    def api_secret
      @api_secret ||= Rails.application.secrets.api_secret
      return @api_secret if @api_secret.present?

      raise "API_SECRET is not set, please check your .env file"
    end
  end
end
