# frozen_string_literal: true

module GitHubClassroom
  module LTI
    module RequestSigning
      def signed_auth_header(endpoint, consumer_key, secret)
        consumer = OAuth::Consumer.new(consumer_key, secret, site: endpoint)
        req = Net::HTTP::Get.new(endpoint, nil)

        auth_signer = OAuth::Client::Helper.new(req, consumer: consumer, request_uri: endpoint)
        auth_signer.hash_body

        auth_signer.header
      end

      def signed_request(endpoint, consumer_key, secret, headers: {})
        headers = { "Authorization": signed_auth_header(endpoint, consumer_key, secret) }.merge(headers)
        opts = {
          url: endpoint,
          headers: headers
        }

        Faraday.new(opts) do |conn|
          conn.response :raise_error
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
