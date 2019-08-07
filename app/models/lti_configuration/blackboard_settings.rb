# frozen_string_literal: true

class LtiConfiguration
  class BlackboardSettings < GenericSettings
    def platform_name
      "Blackboard"
    end

    def icon
      "blackboard-logo.png"
    end

    def supports_membership_service?
      false
    end
  end
end
