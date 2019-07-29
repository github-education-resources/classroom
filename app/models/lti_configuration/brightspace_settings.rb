# frozen_string_literal: true

class LtiConfiguration
  class BrightspaceSettings < GenericSettings
    def initialize
      super(
        platform_name: "Brightspace",
        icon: "brightspace-logo.png"
      )
    end
  end
end
