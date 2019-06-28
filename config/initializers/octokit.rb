# frozen_string_literal: true

require "typhoeus/adapters/faraday"

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError

  builder.request :retry
  builder.adapter :typhoeus
end
