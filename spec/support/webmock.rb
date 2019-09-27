# frozen_string_literal: true

require "webmock/rspec"

# From Octokit.rb
# https://github.com/octokit/octokit.rb/blob/master/spec/helper.rb
def github_url(url)
  return url if url.match?(/^http/)

  url = File.join(Octokit.api_endpoint, url)
  uri = Addressable::URI.parse(url)
  uri.path.gsub!("v3//", "v3/")

  uri.to_s
end
