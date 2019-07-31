# frozen_string_literal: true

class LtiConfiguration
  class GenericSettings
    def platform_name
      nil
    end

    def icon
      nil
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
      false
    end

    def context_memberships_url_key
      "custom_context_memberships_url"
    end
  end
end
