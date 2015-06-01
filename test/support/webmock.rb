require 'webmock/minitest'

def stub_json_request(req, url, body = {}, resp_body)
  stub_request(req, url).
    with(body: body).
    to_return(
      body: resp_body.to_json,
      headers: {'Content-Type' => 'application/json'})
end
