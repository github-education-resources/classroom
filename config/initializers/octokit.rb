stack = Faraday::RackBuilder.new do |builder|
  builder.response :logger
  builder.use Faraday::HttpCache, store: Rails.cache
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack
