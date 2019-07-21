# frozen_string_literal: true

# if Rails.production?
#   Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemcacheStore
# end

Rack::MiniProfiler.config.position = "bottom-right"
Rack::MiniProfiler.toggle_shortcut = "`"
