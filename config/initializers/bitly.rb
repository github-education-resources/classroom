Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3
  config.access_token = Rails.application.secrets.bitly_api_key
end
