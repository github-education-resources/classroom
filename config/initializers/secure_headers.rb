# Setup Secure Headers with default values
# rubocop:disable Lint/PercentStringArray
SecureHeaders::Configuration.default do |config|
  config.csp = {
    default_src: %w[https: 'self'],
    style_src: %w['self' 'unsafe-inline'],
    script_src: %w['self'],
    img_src: %w['self' data: *.githubusercontent.com]
  }
end

# Provide additional permissions on home page for video
# `unauthed_video`
SecureHeaders::Configuration.named_append(:unauthed_video) do
  {
    script_src: %w[https://www.youtube.com https://s.ytimg.com],
    child_src: %w[https://www.youtube.com/ https://s.ytimg.com]
  }
end
# rubocop:enable Lint/PercentStringArray
