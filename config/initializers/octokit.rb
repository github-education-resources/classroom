# frozen_string_literal: true
stack = Faraday::RackBuilder.new do |builder|
  options = {}.tap do |opts|
    opts[:store]        = Rails.cache
    opts[:shared_cache] = false
    opts[:serializer]   = Marshal

    opts[:logger] = Rails.logger unless Rails.env.production?
  end

  builder.use Faraday::HttpCache, options
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack
