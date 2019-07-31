# frozen_string_literal: true

class LtiConfiguration
  class CanvasSettings < GenericSettings
    def platform_name
      "Canvas"
    end

    def icon
      "canvas-logo.png"
    end

    def supports_autoconfiguration?
      true
    end

    def supports_membership_service?
      true
    end

    def vendor_domain
      "canvas.instructure.com"
    end

    # rubocop:disable Metrics/MethodLength
    def vendor_attributes
      {
        privacy_level: "public",
        custom_fields: {
          custom_context_memberships_url: "$ToolProxyBinding.memberships.url"
        },
        course_navigation: {
          windowTarget: "_blank",
          visibility: "admins", # only show the application to instructors
          enabled: "true"
        }
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
