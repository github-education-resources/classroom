# frozen_string_literal: true

class MessageVerifier
  class << self
    def encode(payload, exp = 5.minutes.from_now)
      payload[:exp] ||= exp
      token = verifier.generate payload
    end

    def decode(token)
      body = verifier.verify(token)

      raise ActiveSupport::MessageVerifier::InvalidSignature if Time.now > body[:exp]
      body
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    private

    def verifier
      @verifier = ActiveSupport::MessageVerifier.new(api_secret, digest: 'SHA256')
    end

    def api_secret
      @api_secret ||= Rails.application.secrets.api_secret
      return @api_secret if @api_secret.present?

      raise "API_SECRET is not set, please check your .env file"
    end
  end
end
