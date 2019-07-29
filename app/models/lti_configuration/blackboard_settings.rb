# frozen_string_literal: true

class LtiConfiguration
  class BlackboardSettings < GenericSettings
    def initialize
      super(
        platform_name: "Blackboard",
        icon: "blackboard-logo.png"
      )
    end
  end
end
