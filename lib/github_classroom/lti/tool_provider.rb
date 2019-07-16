# frozen_string_literal: true

require_relative "tool_provider/message_store"
require_relative "tool_provider/membership_service"

module GitHubClassroom
  module LTI
    class ToolProvider
      def initialize(consumer_key: nil, shared_secret: nil)
        raise(ArgumentError, "consumer_key may not be nil") if consumer_key.blank?
        raise(ArgumentError, "shared_secret may not be nil") if shared_secret.blank?

        @consumer_key = consumer_key
        @shared_secret = shared_secret
      end

      def message_store(redis_store)
        @message_store ||= MessageStore.new(consumer_key: @consumer_key, redis_store: redis_store)
      end

      def membership_service(endpoint)
        @membership_service ||= MembershipService.new(endpoint, @consumer_key, @shared_secret)
      end
    end
  end
end
