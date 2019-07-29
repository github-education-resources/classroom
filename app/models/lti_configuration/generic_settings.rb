# frozen_string_literal: true

class LtiConfiguration
  class GenericSettings
    attr_reader :icon, :vendor_domain, :context_memberships_url_key,
      :supports_autoconfiguration, :supports_membership_service

    def initialize(opts = {})
      @platform_name = opts[:platform_name]
      @icon = opts[:icon]
      @vendor_domain = opts[:vendor_domain]
      @context_memberships_url_key = opts[:context_memberships_url_key] || "custom_context_memberships_url"
      @supports_autoconfiguration = opts[:supports_autoconfiguration] || false
      @supports_membership_service = opts[:supports_membership_service] || false
    end

    def platform_name(default_name)
      @platform_name || default_name
    end

    def vendor_attributes
      {}
    end
  end
end
