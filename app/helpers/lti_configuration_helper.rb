# frozen_string_literal: true

module LtiConfigurationHelper
  def lms_type_select_options
    LtiConfiguration.lms_types.map do |k, v|
      if k == "other"
        ["Other learning management system", k]
      else
        [v, k]
      end
    end
  end
end
