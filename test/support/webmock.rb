require 'webmock/minitest'

def stub_get_json(url, response)
  stub_request(:get, url).to_return(
    body: response.to_json,
    headers: {'Content-Type' => 'application/json'})
end
