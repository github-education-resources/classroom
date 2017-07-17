# frozen_string_literal: true

require "typhoeus/adapters/faraday"

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  options = {}.tap do |opts|
    opts[:store]        = Rails.cache
    opts[:shared_cache] = false
    opts[:serializer]   = Marshal

    opts[:logger] = Rails.logger unless Rails.env.production?
  end

  builder.use :http_cache, options

  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError

  builder.request :retry
  builder.adapter :typhoeus
end
