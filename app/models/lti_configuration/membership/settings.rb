# frozen_string_literal: true

class LtiConfiguration
  module Membership
    class Settings
      attr_reader :membership_url, :membership_body_params

      def initialize(membership_url: nil, membership_body_params: nil)
        @membership_url = membership_url
        @membership_body_params = membership_body_params
      end
    end
  end
end
