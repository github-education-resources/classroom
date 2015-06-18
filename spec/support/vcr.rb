require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/cassettes'

  config.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes:  true,
    decode_compressed_response: true
  }

  config.filter_sensitive_data('<<ACCESS_TOKEN>>') do
    test_github_token
  end

  config.hook_into :webmock
end

def test_github_token
  Rails.application.secrets.classroom_test_github_token || 'x' * 40
end
