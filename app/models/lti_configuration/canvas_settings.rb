# frozen_string_literal: true

class LtiConfiguration
  class CanvasSettings < GenericSettings
    def initialize
      super(
        platform_name: "Canvas",
        icon: "canvas-logo.png",
        vendor_domain: "canvas.instructure.com",
        supports_autoconfiguration: true,
        supports_membership_service: true
      )
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
