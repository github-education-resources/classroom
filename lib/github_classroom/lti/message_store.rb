# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class MessageStore
      VALID_LTI_VERSIONS  = ["LTI-1p0"].freeze # LTI-1p0 covers 1.0 and 1.1 and 1.2, but not 1.3
      VALID_MESSAGE_TYPES = ["basic-lti-launch-request"].freeze

      attr_reader :consumer_key

      def initialize(consumer_key: nil, redis_store: nil)
        raise(ArgumentError, "consumer_key may not be nil") if consumer_key.blank?
        raise(ArgumentError, "redis_store may not be nil") if redis_store.blank?

        @consumer_key = consumer_key
        @redis_store = redis_store
      end

      def self.construct_message(params)
        IMS::LTI::Models::Messages::Message.generate(params)
      end

      # rubocop:disable CyclomaticComplexity
      # rubocop:disable AbcSize
      def message_valid?(lti_message)
        # check for duplicate nonce
        return false if nonce_exists?(lti_message.oauth_nonce)

        # check if nonce too old
        return false if DateTime.strptime(lti_message.oauth_timestamp, "%s") < 5.minutes.ago

        # check if required params are provided
        return false unless VALID_MESSAGE_TYPES.include? lti_message.lti_message_type
        return false unless VALID_LTI_VERSIONS.include? lti_message.lti_version

        # check required params for message type
        if lti_message.lti_message_type == "basic-lti-launch-request"
          return false unless lti_message.resource_link_id
        end

        true
      end
      # rubocop:enable AbcSize
      # rubocop:enable CyclomaticComplexity

      def save_message(lti_message)
        nonce = lti_message.oauth_nonce
        scoped = scoped_nonce(nonce)
        if @redis_store.set(scoped, lti_message.to_json)
          nonce
        else
          false
        end
      end

      def get_message(nonce)
        scoped = scoped_nonce(nonce)
        raw_message = @redis_store.get(scoped)
        return nil unless raw_message

        json_message = JSON.parse(raw_message)
        hydrate(json_message)
      end

      def delete_message(nonce)
        scoped = scoped_nonce(nonce)
        @redis_store.del(scoped)
      end

      private

      def nonce_exists?(nonce)
        scoped = scoped_nonce(nonce)
        @redis_store.exists(scoped)
      end

      def hydrate(json_message)
        params = {}
        json_message.each do |param_key, param_value|
          if param_value.is_a?(Hash)
            param_value.each { |k, v| params[k] = v }
          else
            params[param_key] = param_value
          end
        end

        self.class.construct_message(params)
      end

      ##
      # Returns a nonce unique across LMSs
      def scoped_nonce(nonce)
        "#{@consumer_key}-#{nonce}"
      end
    end
  end
end
