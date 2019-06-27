module OmniAuth
  module Strategies
    class Lti
      include OmniAuth::Strategy

      # Hash for storing your Consumer Tools credentials, where:
      # - the key is the consumer_key
      # - the value is the comsumer_secret
      option :consumer_key
      option :shared_secret

      # Default username for users when LTI context doesn't provide a name
      option :default_user_name, 'LTI User'

      def request_phase
        # LTI requests are always initiated from the LMS, 
        # not the tool -- there is no way to do so!
        return fail!(:invalid_request)
      end

      def callback_phase
        # validate request
        return fail!(:invalid_credentials) unless valid_lti?

        # save the launch parameters for use in later request
        env['lti.launch_params'] = @authenticator.params
        super
      
        # rescue more generic OAuth errors and scenarios
        rescue ::Timeout::Error
          fail!(:timeout)
        rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError
          fail!(:service_unavailable)
        rescue ::OmniAuth::NoSessionError
          fail!(:session_expired)
      end

      # define the UID
      uid { @authenticator.params['user_id'] }

      # define the hash of info about user
      info do
        {
          :name => @authenticator.params['username'] || options.default_user_name,
          :email => @authenticator.params['lis_person_contact_email_primary'],
          :first_name => @authenticator.params['lis_person_name_given'],
          :last_name => @authenticator.params['lis_person_name_family'],
          :image => @authenticator.params['user_image']
        }
      end

      # define the hash of credentials
      credentials do
        {
          :token => @authenticator.consumer_key,
        }
      end

      #define extra hash
      extra do
        { :raw_info => @authenticator.params }
      end

      private

      def bad_request!
        [400, {}, ['400 Bad Request']]
      end

      def valid_lti?
        shared_secret = options.shared_secret
        @authenticator = IMS::LTI::Services::MessageAuthenticator.new(request.url, request.params, shared_secret)

        return @authenticator.valid_signature?
      end
    end
  end
end
