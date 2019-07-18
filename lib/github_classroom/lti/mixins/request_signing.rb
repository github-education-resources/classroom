# frozen_string_literal: true

module GitHubClassroom
  module LTI
    module Mixins
      module RequestSigning
        def signed_request(endpoint, consumer_key, secret, query: {}, headers: {})
          uri = URI.parse(endpoint)
          uri.query = URI.encode_www_form(query)
          headers = { "Authorization": signed_auth_header(uri, consumer_key, secret) }.merge(headers)

          opts = { url: uri, headers: headers }
          Faraday.new(opts) do |conn|
            conn.response :raise_error
            conn.adapter Faraday.default_adapter
          end
        end

        private

        def signed_auth_header(uri, consumer_key, secret)
          req = Net::HTTP::Get.new(uri)

          consumer = OAuth::Consumer.new(consumer_key, secret)
          auth_signer = OAuth::Client::Helper.new(req, request_uri: uri, consumer: consumer)
          auth_signer.hash_body

          auth_signer.header
        end
      end
    end
  end
end
