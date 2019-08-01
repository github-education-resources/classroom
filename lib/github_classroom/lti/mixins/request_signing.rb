# frozen_string_literal: true

module GitHubClassroom
  module LTI
    module Mixins
      module RequestSigning
        def signed_request(req, consumer_key, secret, lti_version: 1.1) #, query: {}, headers: {})
          consumer = OAuth::Consumer.new(consumer_key, secret)

          http = Net::HTTP.new(req.uri.host, req.uri.port)
          if lti_version == 1.1
            # necessary to override because LTI 1.1 expects a body hash
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
