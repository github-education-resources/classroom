require 'webmock/minitest'

# From Octokit.rb
# https://github.com/octokit/octokit.rb/blob/master/spec/helper.rb
def github_url(url)
  return url if url =~ /^http/

  url = File.join(Octokit.api_endpoint, url)
  uri = Addressable::URI.parse(url)
  uri.path.gsub!("v3//", "v3/")

  uri.to_s
end

def stub_add_team_membership(team_id, user_login, expected_resp)
  url = github_url("/teams/#{team_id}/memberships/#{user_login}")
  stub_put_json(url, expected_resp)
end

def stub_create_github_team(org_id, options = {}, expected_resp)
  url = github_url("/organizations/#{org_id}/teams")
  stub_post_json(url, options, expected_resp)
end

def stub_github_organization(org_id, expected_resp)
  url = github_url("organizations/#{org_id}")
  stub_get_json(url, expected_resp)
end

def stub_github_team(team_id, expected_resp)
  url = github_url("/teams/#{team_id}")
  stub_get_json(url, expected_resp)
end

def stub_github_user(github_id=nil, expected_resp)
  url = github_url("/user")
  url += github_id.nil? ? '' : "/#{github_id}"

  stub_get_json(url, expected_resp)
end

def stub_users_github_organizations(expected_resp)
  url = github_url('user/orgs')
  stub_get_json(url, expected_resp)
end

def stub_users_github_organization_membership(org_login, expected_resp)
  url = github_url("user/memberships/orgs/#{org_login}")
  stub_get_json(url, expected_resp)
end

private

def stub_get_json(url, expected_resp)
  stub_request(:get, url).
    to_return(
      body: expected_resp.to_json,
      headers: {'Content-Type' => 'application/json'})
end

def stub_post_json(url, body = {}, expected_resp)
  stub_request(:post, url).
    with(body: body.to_json).
    to_return(
      body: expected_resp.to_json,
      headers: {'Content-Type' => 'application/json'})
end

def stub_put_json(url, expected_resp)
  stub_request(:put, url).
    to_return(
      body: expected_resp.to_json,
      headers: {'Content-Type' => 'application/json'})
end
