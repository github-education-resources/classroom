# frozen_string_literal: true

module OmniAuth
  module Strategies
    class OAuth2
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
