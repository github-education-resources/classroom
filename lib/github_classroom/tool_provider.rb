# frozen_string_literal: true

module GitHubClassroom
  class ToolProvider
    def initialize(consumer_key: nil, shared_secret: nil)
      raise(ArgumentError, "consumer_key may not be nil") if consumer_key.blank?
      raise(ArgumentError, "shared_secret may not be nil") if shared_secret.blank?

      @consumer_key = consumer_key
      @shared_secret = shared_secret
    end

    def message_store(redis_store)
      @message_store ||= LTI::MessageStore.new(consumer_key: @consumer_key, redis_store: redis_store)
    end

    def membership_service(endpoint)
      @membership_service ||= LTI::MembershipService.new(endpoint, @consumer_key, @shared_secret)
    end
  end
end
