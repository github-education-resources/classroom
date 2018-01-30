# frozen_string_literal: true

# Setup Secure Headers with default values
SecureHeaders::Configuration.default do |config|
  config.csp = {
    default_src: ["https:", "'self'"],
    style_src: ["'self',", "'unsafe-inline'"],
    script_src: ["'self'"],
    img_src: ["'self'", "data:", "*.githubusercontent.com"]
  }
end

# Provide additional permissions on home page for video
# `unauthed_video`
SecureHeaders::Configuration.named_append(:unauthed_video) do
  {
    script_src: ["https://www.youtube.com", "https://s.ytimg.com"],
    child_src: ["https://www.youtube.com", "https://s.ytimg.com"]
  }
end
