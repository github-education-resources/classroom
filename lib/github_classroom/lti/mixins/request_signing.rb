# frozen_string_literal: true

module GitHubClassroom
  module LTI
    module Mixins
      module RequestSigning
        # given an endpoint, build a Faraday connection which satisfies the LTI standard
        def signed_request(endpoint, lti_version: 1.1, method: :post, headers: {}, query: {}, body: nil)
          req = build_http_req(endpoint, method, headers, query, body)
          sign_request!(req, @consumer_key, @secret, lti_version: lti_version)

          request_headers = {}
          req.each_header { |header, value| request_headers[header] = value }

          connection = Faraday.new(url: req.uri, headers: request_headers) do |conn|
            conn.response :raise_error
            conn.adapter Faraday.default_adapter
          end

          body.present? ? connection.send(method, nil, req.body) : connection.send(method)
        end

        #@@default_lti_request_options = {
        #  lti_version: 1.1,
        #  method: :post,
        #  scheme: :header,
        #  headers: {},
        #  query: {},
        #  body: nil
        #}

        private

        # builds a Net::HTTP request from endpoint and options
        def build_http_req(endpoint, method = :post, headers = {}, query = nil, body = nil)
          uri = URI.parse(endpoint)
          uri.query = URI.encode_www_form(query) if query

          klass = "Net::HTTP::#{method.to_s.capitalize}".constantize
          req = klass.new(uri, headers.stringify_keys)

          if(body.is_a?(Hash))
            req.body = OAuth::Helper.normalize(body)
            req.content_type = 'application/x-www-form-urlencoded'
          else
            req.body = body.to_s
            req["Content-Length"] = req.body.length.to_s
          end

          req
        end

        def sign_request!(req, consumer_key, secret, lti_version: 1.1)
          http = Net::HTTP.new(req.uri.host, req.uri.port)
          consumer = OAuth::Consumer.new(consumer_key, secret)
          if lti_version == 1.1
            # Necessary to override because LTI 1.1 expects a body hash
            # even when the body is empty, as it is in GET requests
            req.instance_variable_set(:@request_has_body, true)
            req.oauth!(http, consumer, nil, scheme: "header")
          elsif lti_version == 1.0
            req.oauth!(http, consumer, nil, scheme: "body")
          end

          req
        end
      end
    end
  end
end
