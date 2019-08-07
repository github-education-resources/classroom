# frozen_string_literal: true

class LtiConfiguration
  class GenericSettings
    delegate :membership_url, to: :membership_settings, prefix: :context
    delegate :membership_body_params, to: :membership_settings, prefix: :context

    def initialize(launch_message)
      @launch_message = launch_message
    end

    def platform_name
      nil
    end

    def icon
      nil
    end

    def lti_version
      1.1
    end

    def vendor_domain
      nil
    end

    def vendor_attributes
      {}
    end

    def supports_autoconfiguration?
      false
    end

    def supports_membership_service?
      context_membership_url.present?
    end

    def membership_settings
      LtiConfiguration::Membership::Settings.new(
        membership_url: (@launch_message.custom_params["custom_context_memberships_url"] if @launch_message)
      )
    end
  end
end
