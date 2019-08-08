# frozen_string_literal: true

class LtiConfiguration
  class SakaiSettings < GenericSettings
    def platform_name
      "Sakai"
    end

    def icon
      "sakai-logo.png"
    end

    def lti_version
      1.0
    end

    def membership_settings
      LtiConfiguration::Membership::Settings.new(
        membership_url: @launch_message.ext_params["ext_ims_lis_memberships_url"],
        membership_body_params: { id: @launch_message.ext_params["ext_ims_lis_memberships_id"] }
      )
    end
  end
end
