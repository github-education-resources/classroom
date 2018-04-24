# frozen_string_literal: true

module GitHub
  class WebHook
    ACCEPTED_EVENTS = %w[ping repository membership organization].freeze

    class << self
      # Public: Generate the [HMAC](https://tools.ietf.org/html/rfc2104)
      # for the given JSON payload.
      #
      # payload - A String representing a JSON payload.
      #
      # Example:
      #
      #   GitHub::WebHook.generate_hmac("{\"login\":\"tarebyte\"}")
      #   # => "fa3d036eb7f341ececf629f5e631e96db778c69e"
      #
      # Returns the HMAC string.
      def generate_hmac(payload)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), webhook_secret, payload)
      end

      private

      # Internal: Returns the GitHub Webhook secret for the application.
      #
      # Returns the secret String or raises an error if it is not defined.
      def webhook_secret
        @webhook_secret ||= Rails.application.secrets.webhook_secret
        return @webhook_secret if @webhook_secret.present?
        raise "WEBHOOK_SECRET is not set, please check you .env file"
      end
    end
  end
end
