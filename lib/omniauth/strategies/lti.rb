# frozen_string_literal: true

module OmniAuth
  module Strategies
    class Lti
      include OmniAuth::Strategy

      # Hash for storing your Consumer Tools credentials, where:
      # - the key is the consumer_key
      # - the value is the comsumer_secret
      option :consumer_key
      option :shared_secret

      def request_phase
        # LTI requests must always be initiated from the LMS,
        # not the tool -- there is no way to do so!
        fail!(:invalid_request)
      end

      def callback_phase
        return fail!(:invalid_credentials) unless valid_lti?
        env["lti.launch_params"] = @authenticator.params

        super
      rescue ::Timeout::Error
        fail!(:timeout)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError
        fail!(:service_unavailable)
      rescue ::OmniAuth::NoSessionError
        fail!(:session_expired)
      end

      uid { @authenticator.params["user_id"] }

      info do
        {
          name: @authenticator.params["username"],
          user_id: @authenticator.params["user_id"],
          email: @authenticator.params["lis_person_contact_email_primary"],
          first_name: @authenticator.params["lis_person_name_given"],
          last_name: @authenticator.params["lis_person_name_family"],
          image: @authenticator.params["user_image"]
        }
      end

      credentials do
        { token: @authenticator.consumer_key }
      end

      extra do
        { raw_info: @authenticator.params }
      end

      private

      def valid_lti?
        shared_secret = options.shared_secret

        @authenticator = IMS::LTI::Services::MessageAuthenticator.new(
          request.url,
          request.params,
          shared_secret
        )

        @authenticator.valid_signature?
      end
    end
  end
end
