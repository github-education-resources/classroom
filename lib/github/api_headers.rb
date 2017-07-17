# frozen_string_literal: true

module GitHub
  module APIHeaders
    class << self
      def no_cache_no_store
        { "Cache-Control" => "no-cache, no-store" }
      end
    end
  end
end
