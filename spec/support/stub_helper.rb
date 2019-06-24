# frozen_string_literal: true

module StubHelper
  def json_file_fixture(path)
    JSON.parse(file_fixture(path).read)
  end

  def stub_access_token_comparison(old_token:, old_scopes: [], new_token:, new_scopes: [])
    stub_check_application_authorization(old_token, scopes: old_scopes)
    stub_check_application_authorization(new_token, scopes: new_scopes)
  end

  def stub_check_application_authorization(token, client_id: Rails.application.secrets.github_client_id, scopes: [])
    response = json_file_fixture("api/oauth_authorizations/check-an-authorization.json")
    url      = "https://api.github.com/applications/#{client_id}/tokens/#{token}"

    response["app"]["client_id"] = client_id if client_id.present?
    response["token"]            = token
    response["scopes"]           = scopes

    stub_request(:get, url).to_return(body: response.to_json, headers: response_headers)
  end

  def stub_get_a_single_user(github_id)
    response = json_file_fixture("api/users/get-a-single-user.json")
    url      = "https://api.github.com/user/#{github_id}"

    response["id"] = github_id
    stub_request(:get, url).to_return(body: response.to_json, headers: response_headers)
  end

  def stub_user(github_id)
    response = json_file_fixture("api/users/get-the-authenticated-user.json")
    url      = "https://api.github.com/user"

    response["id"] = github_id
    stub_request(:get, url).to_return(body: response.to_json, headers: response_headers)
  end

  private

  def response_headers
    {
      "Content-Type": "application/json"
    }
  end
end
