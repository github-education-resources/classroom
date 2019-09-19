# frozen_string_literal: true

module GitHubClassroom
  module LTI
    module Mixins
      module RequestSigning
        DEFAULT_REQUEST_OPTIONS = {
          lti_version: 1.1,
          method: :post,
          headers: {},
          query: {},
          body: nil
        }.freeze

        def lti_request(endpoint, request_options = {})
          opts = DEFAULT_REQUEST_OPTIONS.merge(request_options.symbolize_keys)

          req = build_http_request(endpoint, opts[:method], opts[:headers], opts[:query], opts[:body])
          sign_request!(req, @consumer_key, @secret, lti_version: opts[:lti_version])
          req
        end

        def send_request(req)
          request_headers = {}
          req.each_header { |header, value| request_headers[header] = value }

          connection = Faraday.new(url: req.uri, headers: request_headers) do |conn|
            conn.response :raise_error
            conn.adapter Faraday.default_adapter
            conn.use :gzip
          end

          method = req.method.downcase
          req.body.present? ? connection.send(method, nil, req.body) : connection.send(method, nil)
        end

        private

        def build_http_request(endpoint, method, headers, query, body)
          uri = build_uri(endpoint, query)

          klass = "Net::HTTP::#{method.to_s.capitalize}".constantize
          req = klass.new(uri, headers.stringify_keys)

          if body.is_a?(Hash)
            req.body = OAuth::Helper.normalize(body)
            req.content_type = "application/x-www-form-urlencoded"
          else
            req.body = body.to_s
          end

          req
        end

        def build_uri(endpoint, query)
          uri = URI.parse(endpoint)
          if query
            query.stringify_keys!
            existing_query = Hash[URI.decode_www_form(uri.query || "")]
            uri.query = URI.encode_www_form(query.merge(existing_query))
          end

          uri
        end

        def sign_request!(req, consumer_key, secret, lti_version: 1.1)
          http = Net::HTTP.new(req.uri.host, req.uri.port)
          http.use_ssl = (req.uri.instance_of? URI::HTTPS)

          consumer = OAuth::Consumer.new(consumer_key, secret)
          if lti_version == 1.1
            # Necessary to override because LTI 1.1 expects a body hash
            # even when the body is empty, as it is in GET requests
            req.instance_variable_set(:@request_has_body, true)
            req.oauth!(http, consumer, nil, scheme: "header")
          elsif lti_version == 1.0
            req.oauth!(http, consumer, nil, scheme: "body")
          end
        end
      end
    end
  end
end
