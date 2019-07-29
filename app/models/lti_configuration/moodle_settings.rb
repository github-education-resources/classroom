# frozen_string_literal: true

class LtiConfiguration
  class MoodleSettings < GenericSettings
    def initialize
      super(
        platform_name: "Moodle",
        icon: "moodle-logo.png",
        supports_membership_service: true
      )
    end
  end
end
