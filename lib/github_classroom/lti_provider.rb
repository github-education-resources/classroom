module GitHubClassroom
  class LtiProvider
    def initialize(consumer_key: nil, shared_secret: nil, redis_store: nil)
      @consumer_key = consumer_key
      @shared_secret = shared_secret
      @redis_store = redis_store
    end

    def launch_valid?(launch_request)
      @authenticator = IMS::LTI::Services::MessageAuthenticator(
        launch_request.url,
        launch_request.params,
        @shared_secret)

      # invalid signature
      return false unless authenticator.valid_signature?

      lti_message = authenticator.message

      # duplicate nonce
      return false if nonce_exists?(lti_message.oauth_nonce)

      # nonce too old
      return false if DateTime.strptime(lti_message.oauth_timestamp,'%s') > 5.minutes.ago
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
      raw_message = @redis_store.get(nonce)
      # convert from json
    end

    private

    def nonce_exists?(nonce)
      scoped = scoped_nonce(nonce)
      @redis_store.exists(scoped)
    end

    ##
    # Returns a nonce unique across LMSs
    def scoped_nonce(nonce)
      "#{@consumer_key}-#{nonce}"
    end
  end
end
