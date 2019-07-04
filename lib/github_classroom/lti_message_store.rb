# frozen_string_literal: true

module GitHubClassroom
  class LtiMessageStore
    attr_reader :consumer_key

    def initialize(consumer_key: nil, shared_secret: nil, redis_store: nil)
      raise(ArgumentError, "consumer_key may not be nil") if consumer_key.blank?
      raise(ArgumentError, "shared_secret may not be nil") if shared_secret.blank?
      raise(ArgumentError, "redis_store may not be nil") if redis_store.blank?

      @consumer_key = consumer_key
      @shared_secret = shared_secret
      @redis_store = redis_store
    end

    def self.construct_message(params)
      IMS::LTI::Models::Messages::Message.generate(params)
    end

    def message_valid?(lti_message)
      # check for duplicate nonce
      return false if nonce_exists?(lti_message.oauth_nonce)

      # check if nonce too old
      return false if DateTime.strptime(lti_message.oauth_timestamp, "%s") < 5.minutes.ago

      true
    end

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
