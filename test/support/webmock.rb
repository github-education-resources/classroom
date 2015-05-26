require 'webmock/minitest'

def stub_json_request(req, url, resp)
  stub_request(req, url).to_return(
    body: resp.to_json,
    headers: {'Content-Type' => 'application/json'})
end
