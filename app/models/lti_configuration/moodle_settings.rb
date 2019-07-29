# frozen_string_literal: true

class LtiConfiguration
  class MoodleSettings < GenericSettings
    def platform_name
      "Moodle"
    end

    def icon
      "moodle-logo.png"
    end

    def supports_membership_service
      true
    end
  end
end
