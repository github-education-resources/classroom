# From Octokit.rb
# https://github.com/octokit/octokit.rb/blob/f5f9f2fab804cd2231bd8a33c3a3234504782243/spec/helper.rb#L162
def github_url(url)
  return url if url =~ /^http/

  url = File.join(Octokit.api_endpoint, url)
  uri = Addressable::URI.parse(url)
  uri.path.gsub!("v3//", "v3/")

  uri.to_s
end
